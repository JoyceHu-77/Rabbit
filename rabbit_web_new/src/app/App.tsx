import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence, useScroll, useTransform } from 'motion/react';
import { Heart, Users, Package, CalendarHeart, User, Info, ArrowUp } from 'lucide-react';
import WelcomeModal from './components/WelcomeModal';
import RescueTab from './components/rescue/RescueTab';
import AdoptionTab from './components/adoption/AdoptionTab';
import DonationTab from './components/donation/DonationTab';
import ActivityTab from './components/activity/ActivityTab';
import ProfileTab from './components/profile/ProfileTab';
import { Toaster } from './components/ui/sonner';

type TabType = 'rescue' | 'adoption' | 'donation' | 'activity' | 'profile';

export default function App() {
  const [activeTab, setActiveTab] = useState<TabType>('rescue');
  const [showWelcome, setShowWelcome] = useState(false);
  const [isAdmin, setIsAdmin] = useState(true); // 默认开启管理员模式方便测试
  const [showWelcomeButton, setShowWelcomeButton] = useState(false);
  const [isWelcomeCollapsing, setIsWelcomeCollapsing] = useState(false);
  const [showBackToTop, setShowBackToTop] = useState(false);
  const mainContentRef = useRef<HTMLDivElement>(null);

  const handleTabChange = (tab: TabType) => {
    setActiveTab(tab);
    // 回到顶部并带动画效果
    if (mainContentRef.current) {
      mainContentRef.current.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };

  // 监听滚动显示/隐藏回到顶部按钮
  useEffect(() => {
    const handleScroll = () => {
      if (mainContentRef.current) {
        setShowBackToTop(mainContentRef.current.scrollTop > 300);
      }
    };

    const scrollContainer = mainContentRef.current;
    if (scrollContainer) {
      scrollContainer.addEventListener('scroll', handleScroll);
      return () => scrollContainer.removeEventListener('scroll', handleScroll);
    }
  }, []);

  useEffect(() => {
    const hasSeenWelcome = localStorage.getItem('hasSeenWelcome');
    const lastWelcomeTime = localStorage.getItem('lastWelcomeTime');
    const now = Date.now();

    if (!hasSeenWelcome || !lastWelcomeTime || now - parseInt(lastWelcomeTime) > 24 * 60 * 60 * 1000) {
      setShowWelcome(true);
      setShowWelcomeButton(false);
    } else {
      setShowWelcomeButton(true);
    }
  }, []);

  const handleCloseWelcome = () => {
    setShowWelcome(false);
    localStorage.setItem('hasSeenWelcome', 'true');
    localStorage.setItem('lastWelcomeTime', Date.now().toString());
    // 触发收缩动画
    setIsWelcomeCollapsing(true);
  };

  const handleWelcomeCollapseComplete = () => {
    setIsWelcomeCollapsing(false);
    setShowWelcomeButton(true);
  };

  const tabs = [
    { id: 'rescue', label: '爱兔救援', icon: Heart },
    { id: 'activity', label: '爱兔活动', icon: CalendarHeart },
    { id: 'adoption', label: '爱兔领养', icon: Users },
    { id: 'donation', label: '物资捐换', icon: Package },
    { id: 'profile', label: '个人页', icon: User },
  ] as const;

  return (
    <div className="size-full bg-gradient-to-br from-red-50 via-rose-50 to-pink-50 flex flex-col relative overflow-hidden">
      {/* 装饰性背景元素 */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-20 -left-20 w-60 h-60 bg-red-200/30 rounded-full blur-3xl" />
        <div className="absolute bottom-40 -right-20 w-80 h-80 bg-rose-200/30 rounded-full blur-3xl" />
        <div className="absolute top-1/3 right-1/4 w-40 h-40 bg-pink-200/20 rounded-full blur-2xl" />
      </div>

      <WelcomeModal open={showWelcome} onClose={handleCloseWelcome} onCollapseComplete={handleWelcomeCollapseComplete} />

      {/* 弹窗收缩动画 - 弹窗缩小飞入右上角 */}
      <AnimatePresence>
        {isWelcomeCollapsing && (
          <motion.div
            className="fixed z-[100]"
            initial={{
              top: '50%',
              left: '50%',
              x: '-50%',
              y: '-50%',
              scale: 1,
              opacity: 1,
            }}
            animate={{
              top: '24px',
              left: 'auto',
              right: '24px',
              x: 0,
              y: 0,
              scale: 0.08,
              opacity: 0,
            }}
            transition={{
              duration: 0.6,
              ease: [0.4, 0, 0.2, 1],
            }}
            onAnimationComplete={handleWelcomeCollapseComplete}
          >
            <div className="w-[400px] h-[300px] bg-gradient-to-br from-red-50 via-rose-50 to-pink-50 border-2 border-red-200 rounded-2xl shadow-xl" />
          </motion.div>
        )}
      </AnimatePresence>

      {/* 右上角引导按钮 */}
      <AnimatePresence>
        {showWelcomeButton && !showWelcome && (
          <motion.button
            initial={{ scale: 0, opacity: 0 }}
            animate={{
              scale: 1,
              opacity: 1,
              transition: {
                type: 'spring',
                duration: 0.6,
                delay: 0.3
              }
            }}
            exit={{ scale: 0, opacity: 0 }}
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => {
              // 单击打开新手引导
              setShowWelcome(true);
              setShowWelcomeButton(false);
            }}
            className="fixed top-6 right-6 z-50 w-12 h-12 bg-gradient-to-br from-red-600 to-rose-600 text-white rounded-full shadow-lg hover:shadow-xl transition-shadow flex items-center justify-center group"
          >
            {isAdmin ? <Info size={24} /> : <Info size={24} />}
            {/* 管理员指示器 */}
            {isAdmin && (
              <span className="absolute -top-1 -right-1 w-4 h-4 bg-yellow-400 rounded-full text-xs flex items-center justify-center text-yellow-800 font-bold">A</span>
            )}
            {/* 脉动动画提示 */}
            <motion.div
              initial={{ scale: 1, opacity: 0.6 }}
              animate={{
                scale: [1, 1.3, 1],
                opacity: [0.6, 0, 0.6]
              }}
              transition={{
                duration: 2,
                repeat: Infinity,
                repeatDelay: 1
              }}
              className="absolute inset-0 rounded-full bg-gradient-to-br from-red-600 to-rose-600"
            />
          </motion.button>
        )}
      </AnimatePresence>

      <div className="flex-1 overflow-y-auto pb-20" ref={mainContentRef}>
        <AnimatePresence mode="wait">
          {activeTab === 'rescue' && (
            <motion.div
              key="rescue"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
            >
              <RescueTab isAdmin={isAdmin} />
            </motion.div>
          )}
          {activeTab === 'adoption' && (
            <motion.div
              key="adoption"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
            >
              <AdoptionTab isAdmin={isAdmin} onSectionChange={() => {
              mainContentRef.current?.scrollTo({ top: 0, behavior: 'smooth' });
            }} />
            </motion.div>
          )}
          {activeTab === 'donation' && (
            <motion.div
              key="donation"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
            >
              <DonationTab isAdmin={isAdmin} />
            </motion.div>
          )}
          {activeTab === 'activity' && (
            <motion.div
              key="activity"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
            >
              <ActivityTab isAdmin={isAdmin} onSectionChange={() => {
              mainContentRef.current?.scrollTo({ top: 0, behavior: 'smooth' });
            }} />
            </motion.div>
          )}
          {activeTab === 'profile' && (
            <motion.div
              key="profile"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
            >
              <ProfileTab isAdmin={isAdmin} onAdminToggle={setIsAdmin} />
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <nav className="fixed bottom-0 left-0 right-0 bg-white/95 backdrop-blur-md border-t border-red-100 shadow-lg">
        <div className="flex items-center justify-around max-w-2xl mx-auto px-4 py-3">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;

            return (
              <button
                key={tab.id}
                onClick={() => handleTabChange(tab.id as TabType)}
                className="flex flex-col items-center gap-1 min-w-[60px] relative"
              >
                {isActive && (
                  <motion.div
                    layoutId="activeTab"
                    className="absolute inset-0 bg-gradient-to-br from-pink-100 to-orange-100 rounded-xl"
                    transition={{ type: 'spring', duration: 0.5 }}
                  />
                )}
                <Icon
                  className={`relative z-10 transition-all ${
                    isActive ? 'text-red-600 scale-110' : 'text-gray-400'
                  }`}
                  size={22}
                />
                <span
                  className={`text-xs relative z-10 transition-all ${
                    isActive ? 'text-red-600 font-medium' : 'text-gray-500'
                  }`}
                >
                  {tab.label}
                </span>
              </button>
            );
          })}
        </div>
      </nav>

      <Toaster position="top-center" />

      {/* 回到顶部按钮 */}
      <AnimatePresence>
        {showBackToTop && (
          <motion.button
            initial={{ scale: 0, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0, opacity: 0 }}
            whileTap={{ scale: 0.9 }}
            onClick={() => {
              mainContentRef.current?.scrollTo({ top: 0, behavior: 'smooth' });
            }}
            className="fixed bottom-24 right-4 z-40 w-12 h-12 bg-white border-2 border-red-200 text-red-500 rounded-full shadow-lg hover:shadow-xl flex items-center justify-center transition-shadow"
          >
            <ArrowUp size={20} />
          </motion.button>
        )}
      </AnimatePresence>
    </div>
  );
}