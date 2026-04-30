import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogTitle, DialogDescription } from '../ui/dialog';
import { X, Bell, Package, Award, ShoppingBag, Image as ImageIcon, CheckCircle } from 'lucide-react';
import { motion } from 'motion/react';

export interface Message {
  id: string;
  type: 'system' | 'delivery' | 'reward';
  title: string;
  content: string;
  time: string;
  read: boolean;
}

export interface AdminNotification {
  id: string;
  type: 'payment' | 'order' | 'adopt' | 'cloudAdopt';
  title: string;
  content: string;
  time: string;
  read: boolean;
  orderId?: string;
  screenshot?: string;
}

interface MessagesDialogProps {
  open: boolean;
  onClose: () => void;
  isAdmin?: boolean;
}

// 本地存储管理
const loadAdminNotifications = (): AdminNotification[] => {
  try {
    const saved = localStorage.getItem('adminNotifications');
    if (saved) return JSON.parse(saved);
  } catch (e) {
    console.error('Failed to load admin notifications:', e);
  }
  return [];
};

const saveAdminNotifications = (notifications: AdminNotification[]) => {
  try {
    localStorage.setItem('adminNotifications', JSON.stringify(notifications));
  } catch (e) {
    console.error('Failed to save admin notifications:', e);
  }
};

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

// 导出发送管理员通知的函数
export const sendAdminNotification = (notification: Omit<AdminNotification, 'id' | 'time' | 'read'>) => {
  const notifications = loadAdminNotifications();
  console.log('[AdminNotification] Current notifications:', notifications.length);
  const newNotification: AdminNotification = {
    ...notification,
    id: `NOTIF${Date.now()}`,
    time: new Date().toISOString(),
    read: false,
  };
  notifications.unshift(newNotification);
  saveAdminNotifications(notifications);
  console.log('[AdminNotification] Saved, total:', notifications.length);
  return newNotification;
};

export default function MessagesDialog({ open, onClose, isAdmin = false }: MessagesDialogProps) {
  const [adminNotifications, setAdminNotifications] = useState<AdminNotification[]>([]);
  const [activeTab, setActiveTab] = useState<'user' | 'admin'>('user');

  // 每次打开时从 localStorage 刷新数据
  useEffect(() => {
    if (open) {
      setAdminNotifications(loadAdminNotifications());
      // 如果是管理员且没有切换到管理通知标签，自动切换
      if (isAdmin && activeTab === 'user') {
        setActiveTab('admin');
      }
    }
  }, [open, isAdmin]);

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

  const getAdminIcon = (type: AdminNotification['type']) => {
    switch (type) {
      case 'payment':
        return <ShoppingBag size={20} className="text-pink-500" />;
      case 'cloudAdopt':
        return <ImageIcon size={20} className="text-purple-500" />;
      default:
        return <Bell size={20} className="text-orange-500" />;
    }
  };

  const unreadUserCount = mockMessages.filter(m => !m.read).length;
  const unreadAdminCount = adminNotifications.filter(n => !n.read).length;

  const markAdminAsRead = (id: string) => {
    const updated = adminNotifications.map(n =>
      n.id === id ? { ...n, read: true } : n
    );
    setAdminNotifications(updated);
    saveAdminNotifications(updated);
  };

  const formatTime = (timeStr: string) => {
    const date = new Date(timeStr);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 1) return '刚刚';
    if (minutes < 60) return `${minutes}分钟前`;
    if (hours < 24) return `${hours}小时前`;
    if (days < 7) return `${days}天前`;
    return `${date.getMonth() + 1}-${date.getDate()}`;
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[80vh] overflow-hidden flex flex-col" showClose={false}>
        <DialogTitle className="text-2xl font-bold text-gray-800 flex items-center justify-between flex-shrink-0">
          <div className="flex items-center gap-2">
            <Bell size={24} className="text-red-600" />
            <span>{activeTab === 'user' ? '我的消息' : '管理通知'}</span>
            {activeTab === 'user' && unreadUserCount > 0 && (
              <span className="px-2 py-0.5 bg-red-500 text-white rounded-full text-xs">
                {unreadUserCount}
              </span>
            )}
            {activeTab === 'admin' && unreadAdminCount > 0 && (
              <span className="px-2 py-0.5 bg-orange-500 text-white rounded-full text-xs">
                {unreadAdminCount} 待处理
              </span>
            )}
          </div>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <X size={20} />
          </button>
        </DialogTitle>

        {/* 管理员模式下的标签切换 */}
        {isAdmin && (
          <div className="flex gap-2 mb-4 flex-shrink-0">
            <button
              onClick={() => setActiveTab('user')}
              className={`flex-1 py-2 rounded-lg text-sm font-medium transition-colors ${
                activeTab === 'user'
                  ? 'bg-pink-100 text-pink-700'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              用户消息
            </button>
            <button
              onClick={() => setActiveTab('admin')}
              className={`flex-1 py-2 rounded-lg text-sm font-medium transition-colors flex items-center justify-center gap-1 ${
                activeTab === 'admin'
                  ? 'bg-orange-100 text-orange-700'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              管理通知
              {unreadAdminCount > 0 && (
                <span className="w-2 h-2 bg-orange-500 rounded-full" />
              )}
            </button>
          </div>
        )}

        <DialogDescription className="text-sm text-gray-600 flex-shrink-0">
          {activeTab === 'user' ? '查看您的消息通知和系统提醒' : '查看用户提交的待处理事项'}
        </DialogDescription>

        {/* 用户消息列表 */}
        {activeTab === 'user' && (
          <div className="flex-1 overflow-y-auto space-y-3 mt-4">
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
        )}

        {/* 管理员通知列表 */}
        {activeTab === 'admin' && (
          <div className="flex-1 overflow-y-auto space-y-3 mt-4">
            {adminNotifications.length === 0 ? (
              <div className="text-center py-12">
                <Bell size={48} className="mx-auto text-gray-300 mb-3" />
                <p className="text-gray-500">暂无待处理通知</p>
              </div>
            ) : (
              adminNotifications.map((notification, index) => (
                <motion.div
                  key={notification.id}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.05 }}
                  onClick={() => markAdminAsRead(notification.id)}
                  className={`p-4 rounded-xl border transition-colors cursor-pointer ${
                    notification.read
                      ? 'bg-white border-gray-200'
                      : 'bg-orange-50 border-orange-200'
                  }`}
                >
                  <div className="flex items-start gap-3">
                    <div className="flex-shrink-0 w-10 h-10 rounded-full bg-white border flex items-center justify-center">
                      {getAdminIcon(notification.type)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-1">
                        <h3 className="font-semibold text-gray-800">
                          {notification.title}
                        </h3>
                        <span className="text-xs text-gray-500 flex-shrink-0 ml-2">
                          {formatTime(notification.time)}
                        </span>
                      </div>
                      <p className="text-sm text-gray-600 leading-relaxed">
                        {notification.content}
                      </p>
                      {notification.screenshot && (
                        <div className="mt-2 rounded-lg overflow-hidden border border-gray-200 max-w-[120px]">
                          <img
                            src={notification.screenshot}
                            alt="凭证截图"
                            className="w-full object-contain bg-white"
                          />
                        </div>
                      )}
                      {notification.orderId && (
                        <p className="text-xs text-gray-400 mt-1">
                          订单号：{notification.orderId}
                        </p>
                      )}
                    </div>
                    {!notification.read && (
                      <div className="flex-shrink-0 w-2 h-2 rounded-full bg-orange-500" />
                    )}
                  </div>
                </motion.div>
              ))
            )}
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
