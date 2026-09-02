import { Request, Response } from 'express';
import { authService } from '../services/auth.service';

function userIdFrom(req: Request): string {
  const id = req.headers['x-user-id'];
  if (!id || Array.isArray(id)) {
    throw new Error('Missing x-user-id header (gateway should provide it)');
  }
  return id;
}

export const authController = {
  register: (req: Request, res: Response) =>
    authService.register(req.body).then((r) => res.status(201).json(r)),

  login: (req: Request, res: Response) =>
    authService.login(req.body?.username, req.body?.password).then((r) => res.json(r)),

  refresh: (req: Request, res: Response) =>
    authService.refresh(req.body?.refreshToken).then((r) => res.json(r)),

  logout: (req: Request, res: Response) =>
    authService.logout(req.body?.refreshToken).then((r) => res.json(r)),

  me: (req: Request, res: Response) =>
    authService.me(userIdFrom(req)).then((r) => res.json(r)),

  changePassword: (req: Request, res: Response) =>
    authService
      .changePassword(userIdFrom(req), req.body?.currentPassword, req.body?.newPassword)
      .then((r) => res.json(r)),
};
