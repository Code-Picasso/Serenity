import { randomBytes, randomInt } from 'crypto';
import { config } from '../config';
import { sendEmail } from '../lib/mailer';
import { prisma } from '../lib/prisma';
import {
  ConflictError,
  NotFoundError,
  UnauthorizedError,
  ValidationError,
} from '../utils/errors';
import { signAccessToken, signRefreshToken, tokenExpiryMs, verifyRefreshToken } from '../utils/jwt';
import { comparePassword, hashPassword, sha256 } from '../utils/password';

type UserRecord = {
  id: string;
  email: string;
  name: string;
  avatarUrl: string | null;
  provider: string;
};

interface RegisterInput {
  email: string;
  password: string;
  name: string;
}

function toPublicUser(user: UserRecord) {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    avatarUrl: user.avatarUrl,
    provider: user.provider,
  };
}

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

function generateVerificationCode(): string {
  return randomInt(0, 1_000_000).toString().padStart(6, '0');
}

async function issueVerificationCode(userId: string): Promise<string> {
  const code = generateVerificationCode();
  await prisma.emailVerificationToken.deleteMany({ where: { userId } });
  await prisma.emailVerificationToken.create({
    data: {
      tokenHash: sha256(code),
      userId,
      expiresAt: new Date(Date.now() + config.emailVerificationExpiresMs),
    },
  });
  return code;
}

function sendVerificationEmail(to: string, code: string): Promise<void> {
  const subject = 'Verify your Serenity account';
  const html = `
    <p>Your Serenity verification code is:</p>
    <p style="font-size:24px;font-weight:bold;letter-spacing:4px;">${code}</p>
    <p>This code expires in 24 hours. If you didn't create an account, you can ignore this email.</p>
  `.trim();
  return sendEmail(to, subject, html);
}

function sendResetEmail(to: string, token: string): Promise<void> {
  const link = `${config.appBaseUrl}/reset-password?token=${encodeURIComponent(token)}`;
  const subject = 'Reset your Serenity password';
  const html = `
    <p>Use the token below to reset your password:</p>
    <p><code>${token}</code></p>
    <p>Or open <a href="${link}">${link}</a></p>
  `.trim();
  return sendEmail(to, subject, html);
}

async function issueTokens(user: UserRecord) {
  const accessToken = signAccessToken({ id: user.id, email: user.email, name: user.name });
  const refreshToken = signRefreshToken({ id: user.id, email: user.email, name: user.name });
  await prisma.refreshToken.create({
    data: {
      tokenHash: sha256(refreshToken),
      userId: user.id,
      expiresAt: new Date(tokenExpiryMs(refreshToken)),
    },
  });
  return { accessToken, refreshToken };
}

export const authService = {
  async register(input: RegisterInput) {
    if (!input.email || !input.password || !input.name) {
      throw new ValidationError('email, password and name are required');
    }
    if (input.password.length < 8) {
      throw new ValidationError('Password must be at least 8 characters');
    }
    const email = normalizeEmail(input.email);
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictError('Email is already registered');

    const user = await prisma.user.create({
      data: {
        email,
        name: input.name.trim(),
        passwordHash: await hashPassword(input.password),
        provider: 'credentials',
        isVerified: false,
      },
    });

    const code = await issueVerificationCode(user.id);
    await sendVerificationEmail(user.email, code);

    return {
      message: 'Check your email to verify your account.',
      ...(config.isProduction ? {} : { devVerificationToken: code }),
    };
  },

  async verifyEmail(code: string) {
    if (!code) throw new ValidationError('code is required');
    const tokenHash = sha256(code.trim());
    const stored = await prisma.emailVerificationToken.findUnique({ where: { tokenHash } });
    if (!stored || stored.expiresAt < new Date()) {
      throw new UnauthorizedError('Invalid or expired verification code');
    }
    const user = await prisma.user.findUnique({ where: { id: stored.userId } });
    if (!user) throw new NotFoundError('User not found');

    await prisma.user.update({ where: { id: user.id }, data: { isVerified: true } });
    await prisma.emailVerificationToken.delete({ where: { id: stored.id } });

    return { user: toPublicUser(user), ...(await issueTokens(user)) };
  },

  async resendVerification(email: string) {
    if (!email) throw new ValidationError('email is required');
    const user = await prisma.user.findUnique({ where: { email: normalizeEmail(email) } });
    // Always respond the same to avoid leaking which emails are registered.
    if (!user || user.isVerified) {
      return { message: 'If an unverified account exists for that email, a new code has been sent.' };
    }
    const code = await issueVerificationCode(user.id);
    await sendVerificationEmail(user.email, code);
    return {
      message: 'If an unverified account exists for that email, a new code has been sent.',
      ...(config.isProduction ? {} : { devVerificationToken: code }),
    };
  },

  async login(email: string, password: string) {
    if (!email || !password) throw new ValidationError('email and password are required');
    const user = await prisma.user.findUnique({ where: { email: normalizeEmail(email) } });
    if (!user || !user.passwordHash) {
      throw new UnauthorizedError('Invalid email or password');
    }
    if (!user.isVerified) {
      throw new UnauthorizedError('Email not verified. Check your inbox for a verification code.');
    }
    const ok = await comparePassword(password, user.passwordHash);
    if (!ok) throw new UnauthorizedError('Invalid email or password');
    return { user: toPublicUser(user), ...(await issueTokens(user)) };
  },

  async refresh(refreshToken: string) {
    if (!refreshToken) throw new UnauthorizedError('Refresh token is required');
    let payload: { sub: string };
    try {
      payload = verifyRefreshToken(refreshToken);
    } catch {
      throw new UnauthorizedError('Invalid or expired refresh token');
    }
    const stored = await prisma.refreshToken.findUnique({ where: { tokenHash: sha256(refreshToken) } });
    if (!stored || stored.expiresAt < new Date()) {
      throw new UnauthorizedError('Invalid or expired refresh token');
    }
    const user = await prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user) throw new UnauthorizedError('User no longer exists');

    await prisma.refreshToken.delete({ where: { id: stored.id } });
    return { user: toPublicUser(user), ...(await issueTokens(user)) };
  },

  async logout(refreshToken: string) {
    if (refreshToken) {
      await prisma.refreshToken.deleteMany({ where: { tokenHash: sha256(refreshToken) } });
    }
    return { success: true };
  },

  async me(userId: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundError('User not found');
    return toPublicUser(user);
  },

  async forgotPassword(email: string) {
    if (!email) throw new ValidationError('email is required');
    const user = await prisma.user.findUnique({ where: { email: normalizeEmail(email) } });
    // Always respond the same to avoid leaking which emails are registered.
    if (!user) {
      return { message: 'If that email exists, a reset link has been sent.' };
    }
    const token = randomBytes(32).toString('hex');
    await prisma.passwordResetToken.create({
      data: {
        tokenHash: sha256(token),
        userId: user.id,
        expiresAt: new Date(Date.now() + 60 * 60 * 1000),
      },
    });
    await sendResetEmail(user.email, token);
    return {
      message: 'If that email exists, a reset link has been sent.',
      ...(config.isProduction ? {} : { devResetToken: token }),
    };
  },

  async resetPassword(token: string, newPassword: string) {
    if (!token || !newPassword) throw new ValidationError('token and newPassword are required');
    if (newPassword.length < 8) throw new ValidationError('Password must be at least 8 characters');
    const stored = await prisma.passwordResetToken.findUnique({ where: { tokenHash: sha256(token) } });
    if (!stored || stored.expiresAt < new Date()) {
      throw new UnauthorizedError('Invalid or expired reset token');
    }
    await prisma.user.update({
      where: { id: stored.userId },
      data: { passwordHash: await hashPassword(newPassword) },
    });
    await prisma.passwordResetToken.delete({ where: { id: stored.id } });
    return { message: 'Password updated successfully' };
  },

  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    if (!currentPassword || !newPassword) {
      throw new ValidationError('currentPassword and newPassword are required');
    }
    if (newPassword.length < 8) throw new ValidationError('Password must be at least 8 characters');
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.passwordHash) throw new NotFoundError('User not found');
    const ok = await comparePassword(currentPassword, user.passwordHash);
    if (!ok) throw new UnauthorizedError('Current password is incorrect');
    await prisma.user.update({
      where: { id: userId },
      data: { passwordHash: await hashPassword(newPassword) },
    });
    return { message: 'Password changed successfully' };
  },

};
