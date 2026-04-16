import { useState } from 'react';
import { motion } from 'motion/react';
import { Award, Cloud, Calendar, ShoppingBag } from 'lucide-react';
import CheckinActivity from './CheckinActivity';
import CloudAdoptActivity from './CloudAdoptActivity';
import OfflineEvents from './OfflineEvents';
import CharityShop from './CharityShop';

interface ActivityTabProps {
  isAdmin: boolean;
}

export default function ActivityTab({ isAdmin }: ActivityTabProps) {
  const [activeView, setActiveView] = useState<'banner' | 'events' | 'shop'>('banner');

  const banners = [
    {
      id: 1,
      title: '只取心滴',
      subtitle: '日行一善公益打卡活动',
      bgImage: 'https://images.unsplash.com/photo-1533514114760-4389f572ae26?w=600',
      component: <CheckinActivity />,
    },
    {
      id: 2,
      title: '爱心云养计划',
      subtitle: '公益云养小兔活动',
      bgImage: 'https://images.unsplash.com/photo-1591797057589-eb91f36c0a6f?w=600',
      component: <CloudAdoptActivity />,
    },
  ];

  const [selectedBanner, setSelectedBanner] = useState(banners[0]);

  return (
    <div className="min-h-screen">
      <div className="bg-gradient-to-br from-red-600 via-rose-600 to-pink-600 text-white px-6 py-8">
        <h1 className="text-3xl font-bold mb-2">爱兔活动</h1>
        <p className="text-white/90 text-sm">参与活动，传递爱心</p>
      </div>

      <div className="sticky top-0 bg-white border-b border-red-100 shadow-sm z-10">
        <div className="flex items-center max-w-2xl mx-auto overflow-x-auto">
          <button
            onClick={() => setActiveView('banner')}
            className={`flex-1 min-w-[100px] py-4 px-4 flex flex-col items-center gap-1 relative ${
              activeView === 'banner' ? 'text-red-600' : 'text-gray-500'
            }`}
          >
            {activeView === 'banner' && (
              <motion.div
                layoutId="activeActivityView"
                className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-red-600 to-rose-600"
              />
            )}
            <Award size={20} />
            <span className="text-xs font-medium">活动</span>
          </button>

          <button
            onClick={() => setActiveView('events')}
            className={`flex-1 min-w-[100px] py-4 px-4 flex flex-col items-center gap-1 relative ${
              activeView === 'events' ? 'text-red-600' : 'text-gray-500'
            }`}
          >
            {activeView === 'events' && (
              <motion.div
                layoutId="activeActivityView"
                className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-red-600 to-rose-600"
              />
            )}
            <Calendar size={20} />
            <span className="text-xs font-medium">线下活动</span>
          </button>

          <button
            onClick={() => setActiveView('shop')}
            className={`flex-1 min-w-[100px] py-4 px-4 flex flex-col items-center gap-1 relative ${
              activeView === 'shop' ? 'text-red-600' : 'text-gray-500'
            }`}
          >
            {activeView === 'shop' && (
              <motion.div
                layoutId="activeActivityView"
                className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-red-600 to-rose-600"
              />
            )}
            <ShoppingBag size={20} />
            <span className="text-xs font-medium">爱心橱窗</span>
          </button>
        </div>
      </div>

      <div className="max-w-2xl mx-auto px-4 py-6">
        {activeView === 'banner' && (
          <div className="space-y-6">
            <div className="flex gap-4 overflow-x-auto pb-4">
              {banners.map((banner) => (
                <button
                  key={banner.id}
                  onClick={() => setSelectedBanner(banner)}
                  className={`flex-shrink-0 w-64 h-32 rounded-xl overflow-hidden relative transition-all ${
                    selectedBanner.id === banner.id
                      ? 'ring-4 ring-red-400 scale-105'
                      : 'hover:scale-102'
                  }`}
                >
                  <img
                    src={banner.bgImage}
                    alt={banner.title}
                    className="absolute inset-0 w-full h-full object-cover"
                  />
                  <div className="absolute inset-0 bg-gradient-to-br from-red-600/80 via-rose-600/70 to-pink-600/60" />
                  <div className="relative z-10 p-6 h-full flex flex-col justify-end">
                    <h3 className="text-xl font-bold mb-1 text-white drop-shadow-lg">{banner.title}</h3>
                    <p className="text-sm text-white/95 drop-shadow">{banner.subtitle}</p>
                  </div>
                </button>
              ))}
            </div>

            {selectedBanner.component}
          </div>
        )}

        {activeView === 'events' && <OfflineEvents isAdmin={isAdmin} />}
        {activeView === 'shop' && <CharityShop />}
      </div>
    </div>
  );
}
