import { createHash } from 'crypto';
import bcrypt from 'bcryptjs';

const SALT_ROUNDS = 10;

export async function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, SALT_ROUNDS);
}

export async function comparePassword(plain: string, hash: string): Promise<boolean> {
  return bcrypt.compare(plain, hash);
}

/** Hash a token (refresh/reset) before persisting it so a leaked DB is not enough to replay tokens. */
export function sha256(input: string): string {
  return createHash('sha256').update(input).digest('hex');
}
