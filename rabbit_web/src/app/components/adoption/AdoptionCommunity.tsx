import { useState } from 'react';
import { motion } from 'motion/react';
import { Heart, MessageCircle } from 'lucide-react';
import { Button } from '../ui/button';
import { rabbitDatabase } from '../../../data/rabbitData';
import AdoptionForm from './AdoptionForm';
import { calculateCurrentAge } from '../../../utils/ageCalculator';

interface AdoptionCommunityProps {
  isAdmin: boolean;
}

// 筛选状态为"寄养中"的兔兔
const adoptableRabbits = rabbitDatabase
  .filter(rabbit => rabbit.status === '寄养中')
  .map(rabbit => ({
    id: `R${String(rabbit.id).padStart(3, '0')}`,
    name: rabbit.name,
    image: rabbit.photo,
    age: calculateCurrentAge(rabbit.registrationDate, rabbit.age),
    gender: rabbit.gender === '公' ? '男孩' : '女孩',
    personality: rabbit.description || '温顺亲人',
    healthStatus: rabbit.sterilized === '绝育了' ? '健康，已绝育' : '健康',
  }));

export default function AdoptionCommunity({ isAdmin }: AdoptionCommunityProps) {
  const [showAdoptionForm, setShowAdoptionForm] = useState(false);
  const [selectedRabbit, setSelectedRabbit] = useState<{ id: string; name: string } | null>(null);

  const handleAdopt = (rabbit: typeof adoptableRabbits[0]) => {
    setSelectedRabbit({ id: rabbit.id, name: rabbit.name });
    setShowAdoptionForm(true);
  };

  return (
    <div className="space-y-6">
      <div className="text-center">
        <h2 className="text-2xl font-bold text-gray-800 mb-2">领养社区</h2>
        <p className="text-gray-600">这些可爱的兔兔正在等待一个温暖的家</p>
      </div>

      <div className="grid grid-cols-2 gap-4">
        {adoptableRabbits.map((rabbit, index) => (
          <motion.div
            key={rabbit.id}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: index * 0.1 }}
            className="bg-white rounded-xl overflow-hidden shadow-md hover:shadow-lg transition-shadow"
          >
            <div className="aspect-square relative">
              <img
                src={rabbit.image}
                alt={rabbit.name}
                className="w-full h-full object-cover"
              />
              <div className="absolute top-2 left-2">
                <span className="px-2 py-1 rounded-full bg-purple-500 text-white text-xs font-medium">
                  寄养中
                </span>
              </div>
            </div>

            <div className="p-3 space-y-2">
              <h3 className="font-bold text-gray-800">{rabbit.name}</h3>

              <div className="text-xs text-gray-600 space-y-1">
                <div className="flex justify-between">
                  <span>年龄：{rabbit.age}</span>
                  <span>性别：{rabbit.gender}</span>
                </div>
                <p>性格：{rabbit.personality}</p>
                <p>状态：{rabbit.healthStatus}</p>
              </div>

              <Button
                size="sm"
                onClick={() => handleAdopt(rabbit)}
                className="w-full bg-gradient-to-r from-red-500 to-rose-500 hover:from-purple-600 hover:to-pink-600 text-xs"
              >
                <Heart size={14} className="mr-1" />
                我要领养
              </Button>
            </div>
          </motion.div>
        ))}
      </div>

      <div className="bg-gradient-to-br from-purple-50 to-pink-50 rounded-xl p-6 border border-purple-200">
        <h3 className="font-semibold text-gray-800 mb-3 flex items-center gap-2">
          <MessageCircle size={20} className="text-purple-600" />
          领养须知
        </h3>
        <ul className="text-sm text-gray-600 space-y-2">
          <li className="flex items-start gap-2">
            <span className="text-purple-500">•</span>
            <span>领养需填写意向问卷并通过审核</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-purple-500">•</span>
            <span>需缴纳押金，定期回访后可申请退还</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-purple-500">•</span>
            <span>请确保有充足的时间和精力照顾兔兔</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-purple-500">•</span>
            <span>请提供安全舒适的生活环境</span>
          </li>
        </ul>
      </div>

      {/* 领养申请表单 */}
      {selectedRabbit && (
        <AdoptionForm
          open={showAdoptionForm}
          onClose={() => {
            setShowAdoptionForm(false);
            setSelectedRabbit(null);
          }}
          rabbitName={selectedRabbit.name}
          rabbitId={selectedRabbit.id}
        />
      )}
    </div>
  );
}
