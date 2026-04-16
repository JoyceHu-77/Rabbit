import { Dialog, DialogContent, DialogTitle, DialogDescription } from '../ui/dialog';
import { Calendar, MapPin, Users, X, Image as ImageIcon, Video } from 'lucide-react';
import { Button } from '../ui/button';
import { motion } from 'motion/react';

export interface EventData {
  id: number;
  title: string;
  date: string;
  location: string;
  image: string; // 活动海报（详情页展示）
  bannerImage?: string; // 外露模块背景图（卡片展示）
  description: string;
  type: 'past' | 'upcoming';
  participants?: number;
  images?: string[];
  videos?: string[];
}

interface EventDetailProps {
  event: EventData | null;
  onClose: () => void;
}

export default function EventDetail({ event, onClose }: EventDetailProps) {
  if (!event) return null;

  return (
    <Dialog open={!!event} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto p-0" showClose={false}>
        <DialogTitle className="sr-only">{event.title}</DialogTitle>
        <DialogDescription className="sr-only">
          活动时间：{event.date}，地点：{event.location}
        </DialogDescription>

        {/* 头部 */}
        <div className="sticky top-0 bg-gradient-to-br from-red-600 to-rose-600 text-white px-6 py-4 z-10">
          <button
            onClick={onClose}
            className="absolute top-4 right-4 p-1 hover:bg-white/10 rounded-full transition-colors"
            aria-label="关闭"
          >
            <X size={20} />
          </button>
          <h2 className="text-xl font-bold pr-10" aria-hidden="true">活动详情</h2>
          <p className="text-sm text-white/80 mt-1" aria-hidden="true">
            {event.type === 'past' ? '往期活动' : '未来活动'}
          </p>
        </div>

        <div className="p-6 space-y-6">
          {/* 活动海报 */}
          <div className="rounded-xl overflow-hidden bg-gradient-to-br from-gray-50 to-gray-100 shadow-inner">
            <img
              src={event.image}
              alt={event.title}
              className="w-full max-h-[500px] object-contain"
            />
          </div>

          {/* 活动标题 */}
          <div>
            <h3 className="text-2xl font-bold text-gray-800 mb-4">{event.title}</h3>

            <div className="space-y-3 text-sm">
              <div className="flex items-center gap-2 text-gray-600">
                <Calendar size={18} className="text-red-500" />
                <span className="font-medium">活动时间：</span>
                <span>{event.date}</span>
              </div>

              <div className="flex items-center gap-2 text-gray-600">
                <MapPin size={18} className="text-red-500" />
                <span className="font-medium">活动地点：</span>
                <span>{event.location}</span>
              </div>

              {event.participants && (
                <div className="flex items-center gap-2 text-gray-600">
                  <Users size={18} className="text-red-500" />
                  <span className="font-medium">参与人数：</span>
                  <span>{event.participants} 人</span>
                </div>
              )}
            </div>
          </div>

          {/* 活动描述 */}
          <div className="bg-red-50 rounded-xl p-4">
            <h4 className="font-semibold text-gray-800 mb-3">活动介绍</h4>
            <p className="text-gray-700 leading-relaxed whitespace-pre-line">
              {event.description}
            </p>
          </div>

          {/* 活动图片 */}
          {event.images && event.images.length > 0 && (
            <div>
              <h4 className="font-semibold text-gray-800 mb-3 flex items-center gap-2">
                <ImageIcon size={18} className="text-red-500" />
                活动图片
              </h4>
              <div className="grid grid-cols-2 gap-3">
                {event.images.map((img, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: index * 0.1 }}
                    className="aspect-video rounded-lg overflow-hidden bg-gray-100"
                  >
                    <img
                      src={img}
                      alt={`活动图片 ${index + 1}`}
                      className="w-full h-full object-cover"
                    />
                  </motion.div>
                ))}
              </div>
            </div>
          )}

          {/* 活动视频 */}
          {event.videos && event.videos.length > 0 && (
            <div>
              <h4 className="font-semibold text-gray-800 mb-3 flex items-center gap-2">
                <Video size={18} className="text-red-500" />
                活动视频
              </h4>
              <div className="space-y-3">
                {event.videos.map((video, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.1 }}
                    className="aspect-video rounded-lg overflow-hidden bg-gray-900"
                  >
                    <video
                      src={video}
                      controls
                      className="w-full h-full"
                    >
                      您的浏览器不支持视频播放
                    </video>
                  </motion.div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* 底部按钮 */}
        {event.type === 'upcoming' && (
          <div className="sticky bottom-0 bg-white border-t p-4">
            <Button
              className="w-full bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-700 hover:to-rose-700"
              onClick={() => {
                // 报名逻辑
                onClose();
              }}
            >
              报名参加
            </Button>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
