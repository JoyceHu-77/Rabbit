import { useState } from 'react';
import { motion } from 'motion/react';
import { Button } from '../ui/button';
import { Cloud, Coins, Award } from 'lucide-react';
import badgeImg from '../../../imports/爱兔会徽章1.jpeg';
import CloudAdoptDialog from './CloudAdoptDialog';
import { rabbitDatabase } from '../../../data/rabbitData';

const cloudRabbits = rabbitDatabase
  .filter(rabbit => rabbit.status !== '已去世' && rabbit.status !== '已领养')
  .slice(0, 4)
  .map(rabbit => ({
    id: rabbit.id,
    name: rabbit.name,
    image: rabbit.photo,
    description: rabbit.description || '等待您的爱心云养',
    totalAmount: Math.floor(Math.random() * 2000) + 500,
  }));

export default function CloudAdoptActivity() {
  const [showCloudDialog, setShowCloudDialog] = useState(false);
  const [selectedRabbit, setSelectedRabbit] = useState<{ name: string; image: string } | null>(null);
  const [myCloudCoins, setMyCloudCoins] = useState(0);

  const handleCloudAdopt = (rabbit: typeof cloudRabbits[0]) => {
    setSelectedRabbit({ name: rabbit.name, image: rabbit.image });
    setShowCloudDialog(true);
  };

  return (
    <div className="space-y-6">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-gradient-to-br from-purple-100 to-pink-100 rounded-2xl p-6"
      >
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-purple-800">爱心云养计划</h2>
          <Cloud size={32} className="text-purple-600" />
        </div>

        <p className="text-gray-700 mb-6 leading-relaxed">
          您可自主选择云养的小兔及每月金额，每笔贡献都将在详情页公示并随时可查；
          每月金额的十分之一将作为爱兔会积分，用于兑换橱窗奖品。
          此外，我们将额外加赠一枚爱兔会专属志愿者徽章。
        </p>

        <div className="bg-white rounded-xl p-4 mb-6">
          <h3 className="font-semibold text-gray-800 mb-3">云养规则</h3>
          <ul className="text-sm text-gray-600 space-y-2">
            <li className="flex items-start gap-2">
              <span className="text-purple-500">•</span>
              <span>自主选择云养小兔和月度金额</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-purple-500">•</span>
              <span>每月金额的10%转为云养币，可兑换礼品</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-purple-500">•</span>
              <span>获赠志愿者徽章，支持线上发货或线下领取</span>
            </li>
          </ul>
        </div>

        {/* 志愿者徽章展示 */}
        <div className="bg-gradient-to-br from-pink-50 to-purple-50 rounded-xl p-4 border-2 border-pink-200">
          <div className="flex items-center gap-2 mb-3">
            <Award size={20} className="text-pink-600" />
            <h3 className="font-semibold text-gray-800">专属志愿者徽章</h3>
          </div>
          <div className="flex gap-4 items-center">
            <div className="w-24 h-24 rounded-lg overflow-hidden shadow-md flex-shrink-0">
              <img
                src={badgeImg}
                alt="志愿者徽章"
                className="w-full h-full object-contain bg-white"
              />
            </div>
            <div className="flex-1">
              <p className="text-sm text-gray-600 mb-2">
                参与云养活动即可获得爱兔会专属志愿者徽章一枚
              </p>
              <div className="flex gap-2">
                <Button
                  size="sm"
                  variant="outline"
                  className="text-xs border-pink-300 hover:bg-pink-50"
                >
                  线上发货
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  className="text-xs border-purple-300 hover:bg-purple-50"
                >
                  线下领取
                </Button>
              </div>
            </div>
          </div>
        </div>
      </motion.div>

      <div>
        <h3 className="text-lg font-semibold text-gray-800 mb-4">选择云养小兔</h3>
        <div className="grid grid-cols-2 gap-4">
          {cloudRabbits.map((rabbit) => (
            <motion.div
              key={rabbit.id}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              className="bg-white rounded-xl overflow-hidden shadow-md"
            >
              <div className="aspect-square">
                <img
                  src={rabbit.image}
                  alt={rabbit.name}
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="p-4">
                <h4 className="font-bold text-gray-800 mb-1">{rabbit.name}</h4>
                <p className="text-xs text-gray-600 mb-3">{rabbit.description}</p>
                <div className="flex items-center gap-2 mb-3 text-sm">
                  <Coins size={16} className="text-purple-500" />
                  <span className="text-gray-700">已云养: ¥{rabbit.totalAmount}</span>
                </div>
                <Button
                  size="sm"
                  onClick={() => handleCloudAdopt(rabbit)}
                  className="w-full bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 text-xs"
                >
                  我要云养
                </Button>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-2xl p-6 shadow-md">
        <h3 className="font-semibold text-gray-800 mb-4 flex items-center gap-2">
          <Coins size={20} className="text-purple-600" />
          我的云养币
        </h3>
        <div className="text-center py-8">
          <div className="text-4xl font-bold text-purple-600 mb-2">{myCloudCoins}</div>
          <p className="text-sm text-gray-500">云养币</p>
        </div>
        <Button
          variant="outline"
          className="w-full border-purple-300 hover:bg-purple-50"
        >
          查看我的云养记录
        </Button>
      </div>

      {/* 云养弹窗 */}
      {selectedRabbit && (
        <CloudAdoptDialog
          open={showCloudDialog}
          onClose={() => {
            setShowCloudDialog(false);
            setSelectedRabbit(null);
          }}
          rabbitName={selectedRabbit.name}
          rabbitImage={selectedRabbit.image}
        />
      )}
    </div>
  );
}
