import { Dialog, DialogContent, DialogTitle, DialogDescription } from '../ui/dialog';
import { X, Bell, Package, Award } from 'lucide-react';
import { motion } from 'motion/react';

interface Message {
  id: string;
  type: 'system' | 'delivery' | 'reward';
  title: string;
  content: string;
  time: string;
  read: boolean;
}

interface MessagesDialogProps {
  open: boolean;
  onClose: () => void;
}

const mockMessages: Message[] = [
  {
    id: '1',
    type: 'reward',
    title: '恭喜获得爱兔奖章',
    content: '您在"只取心滴"活动中获得了1枚爱兔奖章，可用于兑换橱窗商品',
    time: '2小时前',
    read: false,
  },
  {
    id: '2',
    type: 'delivery',
    title: '商品已发货',
    content: '您购买的"瓜皮的电子照片"已发货，请查收附件',
    time: '1天前',
    read: false,
  },
  {
    id: '3',
    type: 'system',
    title: '领养申请审核通过',
    content: '您对"啪啪"的领养申请已通过审核，请尽快缴纳押金',
    time: '2天前',
    read: false,
  },
  {
    id: '4',
    type: 'system',
    title: '欢迎加入爱兔会',
    content: '感谢您成为爱兔会的一员，让我们一起为兔兔的幸福而努力！',
    time: '3天前',
    read: true,
  },
];

export default function MessagesDialog({ open, onClose }: MessagesDialogProps) {
  const getIcon = (type: Message['type']) => {
    switch (type) {
      case 'reward':
        return <Award size={20} className="text-red-500" />;
      case 'delivery':
        return <Package size={20} className="text-purple-500" />;
      default:
        return <Bell size={20} className="text-blue-500" />;
    }
  };

  const unreadCount = mockMessages.filter(m => !m.read).length;

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto" showClose={false}>
        <DialogTitle className="text-2xl font-bold text-gray-800 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Bell size={24} className="text-red-600" />
            <span>我的消息</span>
            {unreadCount > 0 && (
              <span className="px-2 py-0.5 bg-red-500 text-white rounded-full text-xs">
                {unreadCount}
              </span>
            )}
          </div>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <X size={20} />
          </button>
        </DialogTitle>
        <DialogDescription className="text-sm text-gray-600">
          查看您的消息通知和系统提醒
        </DialogDescription>

        <div className="space-y-3 mt-4">
          {mockMessages.length === 0 ? (
            <div className="text-center py-12">
              <Bell size={48} className="mx-auto text-gray-300 mb-3" />
              <p className="text-gray-500">暂无消息</p>
            </div>
          ) : (
            mockMessages.map((message, index) => (
              <motion.div
                key={message.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.05 }}
                className={`p-4 rounded-xl border transition-colors cursor-pointer ${
                  message.read
                    ? 'bg-white border-gray-200'
                    : 'bg-red-50 border-red-200'
                }`}
              >
                <div className="flex items-start gap-3">
                  <div className="flex-shrink-0 w-10 h-10 rounded-full bg-white border flex items-center justify-center">
                    {getIcon(message.type)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between mb-1">
                      <h3 className="font-semibold text-gray-800">
                        {message.title}
                      </h3>
                      <span className="text-xs text-gray-500 flex-shrink-0 ml-2">
                        {message.time}
                      </span>
                    </div>
                    <p className="text-sm text-gray-600 leading-relaxed">
                      {message.content}
                    </p>
                  </div>
                  {!message.read && (
                    <div className="flex-shrink-0 w-2 h-2 rounded-full bg-red-500" />
                  )}
                </div>
              </motion.div>
            ))
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
