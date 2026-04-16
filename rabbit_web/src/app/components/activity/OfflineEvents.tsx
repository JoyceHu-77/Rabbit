import { useState } from 'react';
import { motion } from 'motion/react';
import { Calendar, MapPin, Users, Plus } from 'lucide-react';
import { Button } from '../ui/button';
import EventDetail, { EventData } from './EventDetail';
import CreateEventDialog from './CreateEventDialog';
import eventImg1 from '../../../imports/爱兔会活动预告.jpg';
import eventImg2 from '../../../imports/爱兔会活动预告-2.jpeg';

interface OfflineEventsProps {
  isAdmin: boolean;
}

const initialPastEvents: EventData[] = [
  {
    id: 1,
    title: '春日兔友百人聚 - 上海首场',
    date: '2026-04-05',
    location: '市中心6600㎡超大场馆',
    participants: 156,
    image: 'https://images.unsplash.com/photo-1533514114760-4389f572ae26?w=600',
    bannerImage: 'https://images.unsplash.com/photo-1650199321281-978455fbff64?w=600',
    description: '超过150位兔友齐聚一堂，分享养兔经验，交流爱心故事。活动现场气氛热烈，大家互相交流养兔心得，分享与兔兔的温馨故事。',
    type: 'past',
    images: [
      'https://images.unsplash.com/photo-1685650634669-da14c7d662b7?w=600',
      'https://images.unsplash.com/photo-1591797057589-eb91f36c0a6f?w=600',
    ],
  },
];

const initialUpcomingEvents: EventData[] = [
  {
    id: 2,
    title: '春日兔友百人聚',
    date: '2026-04-29',
    location: '市中心6600㎡超大场馆 | 品牌商家赞助',
    image: eventImg1,
    bannerImage: 'https://images.unsplash.com/photo-1765401237810-e403bf6b888d?w=600',
    description: `活动亮点：

1. 丰富礼品：免费饲养用品、免费草卡、兔罐包邮、自由挑选礼盒、限免进场票、限量无门槛体检券、线上积分等

2. 专业服务：专业兔兔鉴赏、健康咨询、品种介绍等专家服务

3. 知识分享：免费讲座、健康诊断、科学养兔培训，定期开展专业教学

欢迎所有爱兔人士参加，让我们一起为兔兔的幸福而努力！`,
    type: 'upcoming',
  },
  {
    id: 3,
    title: '爱兔会公益活动',
    date: '2026-05-15',
    location: '上海市区待定',
    image: eventImg2,
    bannerImage: 'https://images.unsplash.com/photo-1649750291679-1ee88c324527?w=600',
    description: `爱兔会公益活动即将开展，诚邀各位兔友参与：

- 流浪兔救助知识分享
- 科学养兔经验交流
- 领养流程介绍与咨询
- 爱心义卖活动

期待与您相见，共同传递爱心！`,
    type: 'upcoming',
  },
];

export default function OfflineEvents({ isAdmin }: OfflineEventsProps) {
  const [pastEvents, setPastEvents] = useState<EventData[]>(initialPastEvents);
  const [upcomingEvents, setUpcomingEvents] = useState<EventData[]>(initialUpcomingEvents);
  const [selectedEvent, setSelectedEvent] = useState<EventData | null>(null);
  const [showCreateDialog, setShowCreateDialog] = useState(false);

  const handleCreateEvent = (newEvent: Omit<EventData, 'id'>) => {
    const event: EventData = {
      ...newEvent,
      id: Date.now(),
    };

    if (event.type === 'past') {
      setPastEvents([event, ...pastEvents]);
    } else {
      setUpcomingEvents([event, ...upcomingEvents]);
    }
  };

  return (
    <>
      <div className="space-y-8">
        {/* 往期活动 */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-bold text-gray-800">往期活动</h2>
            {isAdmin && (
              <Button
                size="sm"
                onClick={() => setShowCreateDialog(true)}
                className="bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-700 hover:to-rose-700"
              >
                <Plus size={16} className="mr-1" />
                新增活动
              </Button>
            )}
          </div>
          <div className="space-y-4">
            {pastEvents.map((event, index) => (
              <motion.div
                key={event.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                onClick={() => setSelectedEvent(event)}
                className="bg-white rounded-2xl overflow-hidden shadow-md hover:shadow-lg transition-all cursor-pointer"
              >
                <div className="h-48 relative">
                  <img
                    src={event.bannerImage || event.image}
                    alt={event.title}
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute top-4 right-4 px-3 py-1.5 bg-gray-600 text-white rounded-full text-xs font-medium">
                    已结束
                  </div>
                </div>
                <div className="p-6">
                  <h3 className="text-lg font-bold text-gray-800 mb-3">
                    {event.title}
                  </h3>
                  <div className="space-y-2 text-sm text-gray-600 mb-4">
                    <div className="flex items-center gap-2">
                      <Calendar size={16} className="text-red-500" />
                      <span>{event.date}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <MapPin size={16} className="text-red-500" />
                      <span>{event.location}</span>
                    </div>
                    {event.participants && (
                      <div className="flex items-center gap-2">
                        <Users size={16} className="text-red-500" />
                        <span>{event.participants} 人参与</span>
                      </div>
                    )}
                  </div>
                  <p className="text-sm text-gray-600 line-clamp-2">{event.description}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        {/* 未来活动预告 */}
        <div>
          <h2 className="text-xl font-bold text-gray-800 mb-4">未来活动预告</h2>
          <div className="space-y-4">
            {upcomingEvents.map((event, index) => (
              <motion.div
                key={event.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                onClick={() => setSelectedEvent(event)}
                className="bg-gradient-to-br from-red-50 to-rose-50 rounded-2xl overflow-hidden shadow-md border-2 border-red-200 hover:shadow-lg transition-all cursor-pointer"
              >
                <div className="h-48 relative">
                  <img
                    src={event.bannerImage || event.image}
                    alt={event.title}
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute top-4 right-4 px-3 py-1.5 bg-red-500 text-white rounded-full text-xs font-medium">
                    即将开始
                  </div>
                </div>
                <div className="p-6">
                  <h3 className="text-lg font-bold text-gray-800 mb-3">
                    {event.title}
                  </h3>
                  <div className="space-y-2 text-sm text-gray-600 mb-4">
                    <div className="flex items-center gap-2">
                      <Calendar size={16} className="text-red-500" />
                      <span>{event.date}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <MapPin size={16} className="text-red-500" />
                      <span>{event.location}</span>
                    </div>
                  </div>
                  <p className="text-sm text-gray-600 line-clamp-3 mb-4">{event.description}</p>
                  <Button className="w-full bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-700 hover:to-rose-700">
                    查看详情
                  </Button>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>

      {/* 活动详情弹窗 */}
      <EventDetail
        event={selectedEvent}
        onClose={() => setSelectedEvent(null)}
      />

      {/* 新增活动弹窗 */}
      {isAdmin && (
        <CreateEventDialog
          open={showCreateDialog}
          onClose={() => setShowCreateDialog(false)}
          onSubmit={handleCreateEvent}
        />
      )}
    </>
  );
}
