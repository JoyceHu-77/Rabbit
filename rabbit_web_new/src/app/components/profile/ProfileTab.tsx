import { useState, useCallback } from 'react';
import { motion } from 'motion/react';
import {
  User,
  Award,
  Coins,
  Bell,
  MapPin,
  Settings,
  Shield,
  Heart,
  LogOut,
  ShoppingBag,
} from 'lucide-react';
import { Button } from '../ui/button';
import { Avatar, AvatarFallback, AvatarImage } from '../ui/avatar';
import { toast } from 'sonner';
import MessagesDialog from './MessagesDialog';
import AddressDialog from './AddressDialog';
import OrdersDialog from './OrdersDialog';

interface ProfileTabProps {
  isAdmin: boolean;
  onAdminToggle: (isAdmin: boolean) => void;
}

export default function ProfileTab({ isAdmin, onAdminToggle }: ProfileTabProps) {
  const [isLoggedIn, setIsLoggedIn] = useState(true);
  const [showMessages, setShowMessages] = useState(false);
  const [showAddress, setShowAddress] = useState(false);
  const [showOrders, setShowOrders] = useState(false);
  const [user, setUser] = useState({
    name: '爱心用户',
    avatar: '',
    badges: 3,
    cloudCoins: 15,
    bio: '热爱兔兔，致力于救助流浪动物',
  });

  const handleLogin = () => {
    setIsLoggedIn(true);
    toast.success('登录成功');
  };

  const handleLogout = () => {
    setIsLoggedIn(false);
    toast.info('已退出登录');
  };

  const handleCloudCoinsEarned = useCallback((earned: number) => {
    setUser(prev => ({ ...prev, cloudCoins: prev.cloudCoins + earned }));
    toast.success(`${earned} 云养币已到账！`);
  }, []);

  const menuItems = [
    {
      icon: Bell,
      label: '我的消息',
      badge: 3,
      onClick: () => setShowMessages(true),
    },
    {
      icon: ShoppingBag,
      label: '我的订单',
      badge: 0,
      onClick: () => setShowOrders(true),
    },
    {
      icon: Heart,
      label: '我的发布',
      onClick: () => toast.info('查看我的发布'),
    },
    {
      icon: MapPin,
      label: '收货地址',
      onClick: () => setShowAddress(true),
    },
    {
      icon: Settings,
      label: '设置',
      onClick: () => toast.info('打开设置'),
    },
  ];

  if (!isLoggedIn) {
    return (
      <div className="min-h-screen flex items-center justify-center px-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="max-w-sm w-full bg-white rounded-2xl p-8 shadow-lg text-center"
        >
          <div className="w-20 h-20 bg-gradient-to-br from-pink-100 to-purple-100 rounded-full mx-auto mb-6 flex items-center justify-center">
            <User size={40} className="text-red-500" />
          </div>

          <h2 className="text-2xl font-bold text-gray-800 mb-2">欢迎来到爱兔会</h2>
          <p className="text-gray-600 mb-8">登录后享受更多功能</p>

          <Button
            onClick={handleLogin}
            className="w-full bg-gradient-to-r from-pink-500 to-purple-500 hover:from-pink-600 hover:to-purple-600"
          >
            立即登录
          </Button>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-pink-50 via-purple-50 to-orange-50">
      <div className="max-w-2xl mx-auto px-4 py-8 space-y-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gradient-to-br from-pink-500 to-purple-500 rounded-2xl p-6 text-white"
        >
          <div className="flex items-center gap-4 mb-6">
            <Avatar className="w-20 h-20 border-4 border-white">
              <AvatarImage src={user.avatar} />
              <AvatarFallback className="bg-white/20 text-white text-2xl">
                {user.name[0]}
              </AvatarFallback>
            </Avatar>

            <div className="flex-1">
              <div className="flex items-center gap-2 mb-1">
                <h2 className="text-xl font-bold">{user.name}</h2>
                {isAdmin && (
                  <span className="px-2 py-0.5 bg-orange-500 rounded text-xs font-medium flex items-center gap-1">
                    <Shield size={12} />
                    管理员
                  </span>
                )}
              </div>
              <p className="text-white/80 text-sm">{user.bio}</p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="bg-white/20 backdrop-blur-sm rounded-xl p-4 text-center">
              <Award size={24} className="mx-auto mb-2" />
              <div className="text-2xl font-bold">{user.badges}</div>
              <div className="text-xs text-white/80">爱兔奖章</div>
            </div>

            <div className="bg-white/20 backdrop-blur-sm rounded-xl p-4 text-center">
              <Coins size={24} className="mx-auto mb-2" />
              <div className="text-2xl font-bold">{user.cloudCoins}</div>
              <div className="text-xs text-white/80">云养币</div>
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-2xl overflow-hidden shadow-md"
        >
          {menuItems.map((item, index) => {
            const Icon = item.icon;
            return (
              <button
                key={index}
                onClick={item.onClick}
                className="w-full flex items-center justify-between px-6 py-4 hover:bg-gray-50 transition-colors border-b last:border-b-0"
              >
                <div className="flex items-center gap-3">
                  <Icon size={20} className="text-gray-600" />
                  <span className="text-gray-800">{item.label}</span>
                </div>
                <div className="flex items-center gap-2">
                  {item.badge && (
                    <span className="px-2 py-0.5 bg-red-500 text-white rounded-full text-xs">
                      {item.badge}
                    </span>
                  )}
                  <span className="text-gray-400">›</span>
                </div>
              </button>
            );
          })}
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-2xl p-6 shadow-md"
        >
          <h3 className="font-semibold text-gray-800 mb-4">开发者选项</h3>
          <div className="space-y-3">
            <label className="flex items-center justify-between">
              <span className="text-gray-700">管理员模式</span>
              <input
                type="checkbox"
                checked={isAdmin}
                onChange={(e) => onAdminToggle(e.target.checked)}
                className="w-12 h-6 rounded-full appearance-none bg-gray-300 checked:bg-red-500 relative cursor-pointer transition-colors
                  before:content-[''] before:absolute before:w-5 before:h-5 before:rounded-full before:bg-white before:top-0.5 before:left-0.5 before:transition-transform
                  checked:before:translate-x-6"
              />
            </label>
          </div>
        </motion.div>

        <Button
          variant="outline"
          onClick={handleLogout}
          className="w-full border-red-300 hover:bg-red-50 text-red-600"
        >
          <LogOut size={18} className="mr-2" />
          退出登录
        </Button>
      </div>

      {/* 消息对话框 */}
      <MessagesDialog open={showMessages} onClose={() => setShowMessages(false)} isAdmin={isAdmin} />

      {/* 地址管理对话框 */}
      <AddressDialog open={showAddress} onClose={() => setShowAddress(false)} />

      {/* 我的订单对话框 */}
      <OrdersDialog open={showOrders} onClose={() => setShowOrders(false)} onCloudCoinsEarned={handleCloudCoinsEarned} />
    </div>
  );
}
