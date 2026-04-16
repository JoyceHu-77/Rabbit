import { motion } from 'motion/react';
import { Heart, MapPin, Calendar, User } from 'lucide-react';
import { Button } from '../ui/button';

const stories = [
  {
    id: 1,
    name: '雪球',
    image: 'https://images.unsplash.com/photo-1622349817799-067c32295df2?w=600',
    rescueDate: '2026-03-15',
    rescueLocation: '上海市虹口区公园',
    rescuer: '李女士',
    status: '已领养',
    story:
      '雪球是在春天的公园里被发现的，当时它又瘦又小，躲在灌木丛中瑟瑟发抖。经过一个月的精心治疗和照顾，雪球恢复了健康，现在已经找到了爱它的家庭。',
  },
  {
    id: 2,
    name: '小灰',
    image: 'https://images.unsplash.com/photo-1564326140-fa771b2c0c5d?w=600',
    rescueDate: '2026-03-20',
    rescueLocation: '上海市浦东新区',
    rescuer: '王先生',
    status: '寄养中',
    story:
      '小灰在被发现时后腿受伤，经过兽医的专业治疗，现在已经可以正常活动了。它性格温顺，喜欢和人亲近，正在等待一个温暖的家。',
  },
  {
    id: 3,
    name: '布丁',
    image: 'https://images.unsplash.com/photo-1654015619377-2ea602839f98?w=600',
    rescueDate: '2026-02-28',
    rescueLocation: '上海市黄浦区',
    rescuer: '张女士',
    status: '已领养',
    story:
      '布丁是一只活泼可爱的棕色小兔，被发现时正在街边觅食。经过寄养家庭的悉心照料，布丁变得越来越健康，现在已经有了属于自己的家。',
  },
];

export default function RabbitStorybook() {
  return (
    <div className="space-y-6">
      <div className="text-center mb-8">
        <h2 className="text-2xl font-bold text-gray-800 mb-2">兔兔故事书</h2>
        <p className="text-gray-600">记录每一只兔兔的救援之路</p>
      </div>

      {stories.map((story, index) => (
        <motion.div
          key={story.id}
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: index * 0.15 }}
          className="bg-white rounded-2xl overflow-hidden shadow-lg"
        >
          <div className="relative h-64">
            <img
              src={story.image}
              alt={story.name}
              className="w-full h-full object-cover"
            />
            <div className="absolute top-4 right-4">
              <span className="px-3 py-1.5 rounded-full bg-white/90 backdrop-blur-sm text-sm font-medium text-purple-700 border border-purple-200">
                {story.status}
              </span>
            </div>
            <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/60 to-transparent p-6">
              <h3 className="text-2xl font-bold text-white flex items-center gap-2">
                <Heart size={24} className="text-red-400" />
                {story.name}
              </h3>
            </div>
          </div>

          <div className="p-6 space-y-4">
            <div className="grid grid-cols-2 gap-3 text-sm">
              <div className="flex items-center gap-2 text-gray-600">
                <Calendar size={16} className="text-purple-500" />
                <span>{story.rescueDate}</span>
              </div>
              <div className="flex items-center gap-2 text-gray-600">
                <User size={16} className="text-purple-500" />
                <span>{story.rescuer}</span>
              </div>
              <div className="flex items-center gap-2 text-gray-600 col-span-2">
                <MapPin size={16} className="text-purple-500" />
                <span>{story.rescueLocation}</span>
              </div>
            </div>

            <div className="border-t pt-4">
              <h4 className="font-semibold text-gray-800 mb-2">救援故事</h4>
              <p className="text-gray-600 leading-relaxed">{story.story}</p>
            </div>
          </div>
        </motion.div>
      ))}
    </div>
  );
}
