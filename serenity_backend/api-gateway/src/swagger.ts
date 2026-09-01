import { Express } from 'express';
import fs from 'fs';
import path from 'path';
import swaggerUi from 'swagger-ui-express';
import YAML from 'yaml';

export function setupSwagger(app: Express): void {
  const filePath = path.join(process.cwd(), 'openapi.yaml');
  if (!fs.existsSync(filePath)) {
    console.warn('[gateway:swagger] openapi.yaml not found; docs disabled');
    return;
  }
  const raw = fs.readFileSync(filePath, 'utf8');
  const doc = YAML.parse(raw);

  app.use('/docs', swaggerUi.serve, swaggerUi.setup(doc));
  app.get('/openapi.yaml', (_req, res) => res.type('application/yaml').send(raw));
  app.get('/openapi', (_req, res) => res.json(doc));
}
