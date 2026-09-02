import nodemailer from 'nodemailer';
import type { Transporter } from 'nodemailer';
import { config } from '../config';

function createTransporter(): Transporter | null {
  if (!config.smtp.host) return null;
  return nodemailer.createTransport({
    host: config.smtp.host,
    port: config.smtp.port,
    secure: config.smtp.secure,
    auth: config.smtp.user ? { user: config.smtp.user, pass: config.smtp.pass } : undefined,
  });
}

const transporter = createTransporter();

export async function sendEmail(to: string, subject: string, html: string): Promise<void> {
  if (!transporter) {
    console.warn(`[mail] SMTP not configured; email to ${to} not sent. Subject: ${subject}`);
    return;
  }
  await transporter.sendMail({ from: config.smtp.from, to, subject, html });
}
