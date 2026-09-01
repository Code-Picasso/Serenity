import { Router } from 'express';
import { chatController } from '../controllers/chat.controller';
import { asyncHandler } from '../middleware/asyncHandler';
import { audioUpload } from '../middleware/upload';

const router = Router();

router.get('/conversations', asyncHandler(chatController.listConversations));
router.post('/conversations', asyncHandler(chatController.createConversation));
router.get('/conversations/:id', asyncHandler(chatController.getConversation));
router.get('/conversations/:id/messages', asyncHandler(chatController.listMessages));
router.post('/conversations/:id/messages', asyncHandler(chatController.sendMessage));
router.post(
  '/conversations/:id/messages/audio',
  audioUpload.single('audio'),
  asyncHandler(chatController.sendAudioMessage),
);
router.post('/conversations/:id/read', asyncHandler(chatController.markRead));

export default router;
