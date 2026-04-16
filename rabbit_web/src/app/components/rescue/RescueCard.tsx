import { MapPin, Calendar, Heart, Check, User } from 'lucide-react';
import { RescuePost } from './RescueTab';

interface RescueCardProps {
  post: RescuePost;
}

const statusColors = {
  '待救援': 'bg-red-100 text-red-700 border-red-300',
  '救援中': 'bg-orange-100 text-orange-700 border-orange-300',
  '已救援': 'bg-blue-100 text-blue-700 border-blue-300',
  '寄养中': 'bg-purple-100 text-purple-700 border-purple-300',
  '已领养': 'bg-green-100 text-green-700 border-green-300',
};

export default function RescueCard({ post }: RescueCardProps) {
  return (
    <div className="bg-white rounded-xl overflow-hidden shadow-md hover:shadow-lg transition-all cursor-pointer">
      <div className="aspect-square relative">
        <img
          src={post.images[0]}
          alt={post.title}
          className="w-full h-full object-cover"
          onError={(e) => {
            (e.target as HTMLImageElement).src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 400 400"%3E%3Crect fill="%23f3f4f6" width="400" height="400"/%3E%3Ctext fill="%239ca3af" font-family="sans-serif" font-size="24" x="50%25" y="50%25" text-anchor="middle" dy=".3em"%3E🐰%3C/text%3E%3C/svg%3E';
          }}
        />
        <div className="absolute top-2 right-2">
          <span
            className={`text-xs px-2 py-1 rounded-full border ${
              statusColors[post.status]
            } backdrop-blur-sm`}
          >
            {post.status}
          </span>
        </div>
      </div>

      <div className="p-3">
        <h3 className="font-semibold text-sm text-gray-800 mb-2 line-clamp-1">
          {post.title}
        </h3>

        {/* 地点和日期 - 左右结构 */}
        <div className="grid grid-cols-2 gap-x-2 gap-y-1 text-xs text-gray-600 mb-2">
          <div className="flex items-center gap-1">
            <MapPin size={12} className="text-red-500 flex-shrink-0" />
            <span className="line-clamp-1">{post.location}</span>
          </div>
          <div className="flex items-center gap-1">
            <Calendar size={12} className="text-red-500 flex-shrink-0" />
            <span className="line-clamp-1">{post.date}</span>
          </div>
        </div>

        {/* 主理人信息 */}
        {post.organizer && (
          <div className="flex items-center gap-1 text-xs text-gray-600 mb-2">
            <User size={12} className="text-purple-500 flex-shrink-0" />
            <span>主理人：{post.organizer.name}</span>
          </div>
        )}

        {/* 健康状态和绝育状态 - 左右结构 */}
        {(post.healthStatus || post.sterilizedStatus) && (
          <div className="grid grid-cols-2 gap-2 mb-2">
            {post.healthStatus && (
              <div className="flex items-center gap-1 px-2 py-1 bg-green-50 rounded text-xs">
                <Heart size={12} className="text-green-500 flex-shrink-0" />
                <span className="text-green-700 line-clamp-1">{post.healthStatus}</span>
              </div>
            )}
            {post.sterilizedStatus && (
              <div className="flex items-center gap-1 px-2 py-1 bg-blue-50 rounded text-xs">
                <Check size={12} className="text-blue-500 flex-shrink-0" />
                <span className="text-blue-700 line-clamp-1">{post.sterilizedStatus}</span>
              </div>
            )}
          </div>
        )}

        <p className="text-xs text-gray-500 line-clamp-2">
          {post.description}
        </p>
      </div>
    </div>
  );
}
