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
  username: string;
  name: string;
  gender: string;
  avatarUrl: string | null;
  provider: string;
};

/** Accepted gender values. Stored lowercase; the app renders the labels. */
export const GENDERS = ['male', 'female', 'other', 'prefer_not_to_say'] as const;

const USERNAME_PATTERN = /^[a-z0-9_.]{3,30}$/;

interface RegisterInput {
  username: string;
  password: string;
  name: string;
  gender: string;
}

function toPublicUser(user: UserRecord) {
  return {
    id: user.id,
    username: user.username,
    name: user.name,
    gender: user.gender,
    avatarUrl: user.avatarUrl,
    provider: user.provider,
  };
}

function normalizeUsername(username: string): string {
  return username.trim().toLowerCase();
}

function normalizeGender(gender: string): string {
  return gender.trim().toLowerCase().replace(/[\s-]+/g, '_');
}

async function issueTokens(user: UserRecord) {
  const accessToken = signAccessToken({ id: user.id, username: user.username, name: user.name });
  const refreshToken = signRefreshToken({ id: user.id, username: user.username, name: user.name });
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
    if (!input.username || !input.password || !input.name || !input.gender) {
      throw new ValidationError('username, password, name and gender are required');
    }
    if (input.password.length < 8) {
      throw new ValidationError('Password must be at least 8 characters');
    }

    const username = normalizeUsername(input.username);
    if (!USERNAME_PATTERN.test(username)) {
      throw new ValidationError(
        'Username must be 3-30 characters, using only letters, numbers, underscore or dot',
      );
    }

    const gender = normalizeGender(input.gender);
    if (!(GENDERS as readonly string[]).includes(gender)) {
      throw new ValidationError(`gender must be one of: ${GENDERS.join(', ')}`);
    }

    const existing = await prisma.user.findUnique({ where: { username } });
    if (existing) throw new ConflictError('Username is already taken');

    const user = await prisma.user.create({
      data: {
        username,
        name: input.name.trim(),
        gender,
        passwordHash: await hashPassword(input.password),
        provider: 'credentials',
      },
    });

    // No email verification step: the account is usable immediately.
    return { user: toPublicUser(user), ...(await issueTokens(user)) };
  },

  async login(username: string, password: string) {
    if (!username || !password) throw new ValidationError('username and password are required');
    const user = await prisma.user.findUnique({ where: { username: normalizeUsername(username) } });
    if (!user || !user.passwordHash) {
      throw new UnauthorizedError('Invalid username or password');
    }
    const ok = await comparePassword(password, user.passwordHash);
    if (!ok) throw new UnauthorizedError('Invalid username or password');
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
