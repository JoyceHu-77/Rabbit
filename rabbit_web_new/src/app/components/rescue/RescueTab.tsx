import { useState, useEffect } from 'react';
import { Plus, Filter, ArrowUpDown, Search, X } from 'lucide-react';
import { Button } from '../ui/button';
import { motion } from 'motion/react';
import { Input } from '../ui/input';
import RescueCard from './RescueCard';
import RescueFilters from './RescueFilters';
import CreateRescuePost from './CreateRescuePost';
import RescueDetail from './RescueDetail';
import RabbitLoading from './RabbitLoading';
import { rabbitDatabase, type RabbitData } from '../../../data/rabbitData';
import { calculateCurrentAge } from '../../../utils/ageCalculator';

interface RescueTabProps {
  isAdmin: boolean;
}

export type RescueStatus = '待救援' | '救援中' | '已救援' | '寄养中' | '已领养' | '已去世';

export interface RescuePost {
  id: string;
  title: string;
  description: string;
  images: string[];
  location: string;
  city: string;
  district: string;
  date: string;
  status: RescueStatus;
  finder?: {
    name: string;
    contact: string;
    isPublic: boolean;
  };
  organizer?: {
    name: string;
    contact: string;
    isPublic: boolean;
  };
  wechatQR?: string;
  healthStatus?: string;
  sterilizedStatus?: string;
}

// 解析中文日期格式 "2025年6月" 或 "2025年6月1日" 为 Date 对象
const parseChineseDate = (dateStr: string): Date => {
  // 匹配 "2025年6月" 或 "2025年6月1日" 格式
  const match = dateStr.match(/(\d{4})年(\d{1,2})月(\d{1,2})?日?/);
  if (match) {
    const year = parseInt(match[1]);
    const month = parseInt(match[2]) - 1; // 月份从0开始
    const day = match[3] ? parseInt(match[3]) : 1;
    return new Date(year, month, day);
  }
  // 如果解析失败，返回一个很旧的日期
  return new Date(1900, 0, 1);
};

// 将兔兔数据转换为救援帖子格式
const convertRabbitToPost = (rabbit: RabbitData): RescuePost => {
  const locationParts = rabbit.location.split('-');
  const city = locationParts[0] || '上海市';
  const district = locationParts[1] || '';

  // 已去世的兔兔显示特殊文本，其他兔兔计算当前年龄
  const displayAge = rabbit.status === '已去世'
    ? '再也不会老去的天使👼'
    : calculateCurrentAge(rabbit.registrationDate, rabbit.age);

  // 从描述中提取健康状态和绝育状态
  const healthMatch = rabbit.description?.match(/健康状况：([^；]+)/);
  const sterilizedMatch = rabbit.description?.match(/绝育状态：([^；]+)/);

  // 清理描述，移除健康状况和绝育状态的文本
  let cleanDescription = rabbit.description || '';
  cleanDescription = cleanDescription.replace(/健康状况：[^；]+；?/g, '');
  cleanDescription = cleanDescription.replace(/绝育状态：[^；]+；?/g, '');
  cleanDescription = cleanDescription.replace(/；\s*$/, '').trim();
  cleanDescription = cleanDescription.replace(/\s*；\s*$/, '').trim();

  return {
    id: `R${String(rabbit.id).padStart(3, '0')}`,
    title: rabbit.name ? `${rabbit.name} - ${displayAge}` : displayAge,
    description: cleanDescription,
    images: [rabbit.photo],
    location: rabbit.location,
    city,
    district,
    date: rabbit.registrationDate,
    status: rabbit.status,
    finder: rabbit.finder,
    organizer: rabbit.organizer,
    wechatQR: rabbit.wechatQRCode,
    healthStatus: healthMatch?.[1],
    sterilizedStatus: sterilizedMatch?.[1],
  };
};

const initialPosts = rabbitDatabase.map(convertRabbitToPost);

// 从 localStorage 加载保存的帖子数据
export const loadSavedPosts = (): RescuePost[] => {
  try {
    const saved = localStorage.getItem('savedRescuePosts');
    if (saved) {
      const savedPosts = JSON.parse(saved);
      // 合并初始数据和已保存的数据（已保存的数据优先级更高）
      return initialPosts.map(initialPost => {
        const savedPost = savedPosts.find((p: RescuePost) => p.id === initialPost.id);
        return savedPost ? { ...initialPost, ...savedPost } : initialPost;
      });
    }
  } catch (e) {
    console.error('Failed to load saved posts:', e);
  }
  return initialPosts;
};

// 保存帖子数据到 localStorage
const savePostsToStorage = (posts: RescuePost[]) => {
  try {
    localStorage.setItem('savedRescuePosts', JSON.stringify(posts));
  } catch (e) {
    console.error('Failed to save posts:', e);
  }
};

export default function RescueTab({ isAdmin }: RescueTabProps) {
  const [allPosts, setAllPosts] = useState<RescuePost[]>(loadSavedPosts);
  const [posts, setPosts] = useState<RescuePost[]>(loadSavedPosts);
  const [showFilters, setShowFilters] = useState(false);
  const [showCreate, setShowCreate] = useState(false);
  const [selectedPost, setSelectedPost] = useState<RescuePost | null>(null);
  const [sortBy, setSortBy] = useState<'latest' | 'earliest'>('latest');
  const [searchQuery, setSearchQuery] = useState('');
  const [activeFilters, setActiveFilters] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(false);

  // 计算可用日期列表（用于日历禁用无数据的日期）
  const availableDates = allPosts
    .filter(post => post.date !== '未知')
    .map(post => parseChineseDate(post.date));

  useEffect(() => {
    // 显示加载动画
    setIsLoading(true);

    // 模拟加载延迟（2秒后隐藏加载动画）
    const loadingTimer = setTimeout(() => {
      setIsLoading(false);
    }, 2000);

    let filtered = [...allPosts];

    // 搜索过滤
    if (searchQuery.trim()) {
      filtered = filtered.filter(post =>
        post.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        post.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
        post.description.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }

    // 应用筛选条件
    if (activeFilters) {
      // 状态筛选
      if (activeFilters.statuses && activeFilters.statuses.length > 0) {
        filtered = filtered.filter(post =>
          activeFilters.statuses.includes(post.status)
        );
      }

      // 地区筛选
      if (activeFilters.districts && activeFilters.districts.length > 0) {
        filtered = filtered.filter(post =>
          activeFilters.districts.some((district: string) =>
            post.location.includes(district)
          )
        );
      }

      // 日期筛选（未知日期的帖子不参与筛选）
      if (activeFilters.dateRange) {
        const { from, to } = activeFilters.dateRange;
        if (from) {
          filtered = filtered.filter(post => {
            // 跳过未知日期的帖子
            if (post.date === '未知') return false;

            const postDate = parseChineseDate(post.date);
            const fromDate = from;
            if (to) {
              return postDate >= fromDate && postDate <= to;
            }
            return postDate >= fromDate;
          });
        }
      }

      // 我的发布筛选（这里简单模拟，实际需要用户ID）
      if (activeFilters.myPosts) {
        // TODO: 实际应该根据当前登录用户ID筛选
        filtered = filtered.filter(post =>
          post.finder && post.finder.name === '张女士' // 示例
        );
      }
    }

    // 排序：未知日期排最后，有日期的按时间排序
    filtered.sort((a, b) => {
      const dateA = parseChineseDate(a.date);
      const dateB = parseChineseDate(b.date);
      const isKnownA = a.date !== '未知';
      const isKnownB = b.date !== '未知';

      // 两者都是未知，按原始顺序
      if (!isKnownA && !isKnownB) return 0;
      // 已知排前面，未知排后面
      if (!isKnownA) return 1;
      if (!isKnownB) return -1;

      // 都有日期，按时间排序
      return sortBy === 'latest'
        ? dateB.getTime() - dateA.getTime()
        : dateA.getTime() - dateB.getTime();
    });

    setPosts(filtered);

    return () => clearTimeout(loadingTimer);
  }, [searchQuery, sortBy, allPosts, activeFilters]);

  const handleSort = () => {
    setSortBy(sortBy === 'latest' ? 'earliest' : 'latest');
  };

  const handleCreatePost = (newPost: Omit<RescuePost, 'id'>) => {
    const post: RescuePost = {
      ...newPost,
      id: `R${String(allPosts.length + 1).padStart(3, '0')}`,
    };
    const updatedPosts = [post, ...allPosts];
    setAllPosts(updatedPosts);
    setPosts(updatedPosts);
    savePostsToStorage(updatedPosts);
    setShowCreate(false);
  };

  return (
    <>
      <div className="min-h-screen">
        <div className="bg-gradient-to-br from-red-600 to-rose-600 text-white px-6 py-8">
          <h1 className="text-3xl font-bold mb-6">🐰 爱兔救援</h1>

          <div className="mb-4">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={18} />
              <Input
                type="text"
                placeholder="搜索兔兔姓名、编号..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10 bg-white/90 border-white/30 text-gray-800 placeholder:text-gray-500"
              />
            </div>
          </div>

          <div className="flex gap-3">
            <Button
              variant="secondary"
              size="sm"
              onClick={handleSort}
              className="flex items-center gap-2 bg-white/20 hover:bg-white/30 text-white border-white/30"
            >
              <ArrowUpDown size={16} />
              {sortBy === 'latest' ? '最新发布' : '最早发布'}
            </Button>

            <Button
              variant="secondary"
              size="sm"
              onClick={() => setShowFilters(!showFilters)}
              className="flex items-center gap-2 bg-white/20 hover:bg-white/30 text-white border-white/30"
            >
              <Filter size={16} />
              筛选
            </Button>
          </div>
        </div>

        {showFilters && (
          <RescueFilters
            onFilter={(filters) => setActiveFilters(filters)}
            onClose={() => setShowFilters(false)}
            availableDates={availableDates}
          />
        )}

        {/* 已选筛选条件展示 */}
        {(() => {
          const hasStatuses = activeFilters?.statuses?.length > 0;
          const hasDistricts = activeFilters?.districts?.length > 0;
          const hasDate = !!activeFilters?.dateRange?.from;
          const hasMyPosts = !!activeFilters?.myPosts;
          const totalFilters = (hasStatuses ? activeFilters.statuses.length : 0) +
                              (hasDistricts ? activeFilters.districts.length : 0) +
                              (hasDate ? 1 : 0) +
                              (hasMyPosts ? 1 : 0);

          if (totalFilters === 0) return null;

          return (
            <div className="px-4 py-2 bg-white border-b border-red-100">
              <div className="max-w-2xl mx-auto">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="text-xs text-gray-500">已选:</span>
                  {activeFilters.statuses?.map((status: string) => (
                    <button
                      key={status}
                      onClick={() => {
                        const newStatuses = activeFilters.statuses.filter((s: string) => s !== status);
                        setActiveFilters({ ...activeFilters, statuses: newStatuses });
                      }}
                      className="inline-flex items-center gap-1 px-2 py-1 bg-red-100 text-red-600 rounded-full text-xs"
                    >
                      {status}
                      <X size={12} />
                    </button>
                  ))}
                  {activeFilters.districts?.map((district: string) => (
                    <button
                      key={district}
                      onClick={() => {
                        const newDistricts = activeFilters.districts.filter((d: string) => d !== district);
                        setActiveFilters({ ...activeFilters, districts: newDistricts });
                      }}
                      className="inline-flex items-center gap-1 px-2 py-1 bg-red-100 text-red-600 rounded-full text-xs"
                    >
                      {district}
                      <X size={12} />
                    </button>
                  ))}
                  {activeFilters.dateRange?.from && (
                    <button
                      onClick={() => {
                        setActiveFilters({ ...activeFilters, dateRange: {} });
                      }}
                      className="inline-flex items-center gap-1 px-2 py-1 bg-red-100 text-red-600 rounded-full text-xs"
                    >
                      {activeFilters.dateRange.from.toLocaleDateString()}-{activeFilters.dateRange.to?.toLocaleDateString() || ''}
                      <X size={12} />
                    </button>
                  )}
                  {activeFilters.myPosts && (
                    <button
                      onClick={() => {
                        setActiveFilters({ ...activeFilters, myPosts: false });
                      }}
                      className="inline-flex items-center gap-1 px-2 py-1 bg-red-100 text-red-600 rounded-full text-xs"
                    >
                      我的发布
                      <X size={12} />
                    </button>
                  )}
                  {totalFilters > 1 && (
                    <button
                      onClick={() => setActiveFilters(null)}
                      className="text-xs text-gray-400 hover:text-red-500 ml-2"
                    >
                      清除全部
                    </button>
                  )}
                </div>
              </div>
            </div>
          );
        })()}

        <div className="px-4 py-6">
          {isLoading ? (
            <RabbitLoading />
          ) : posts.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 bg-gradient-to-b from-red-50 to-white rounded-3xl">
              <div className="text-8xl mb-4 animate-bounce">🐰</div>
              <p className="text-xl text-gray-600 font-medium mb-2">没有找到兔兔</p>
              <p className="text-sm text-gray-400 mb-6">试试调整筛选条件或发布新的救援信息</p>
              <Button
                onClick={() => setShowCreate(true)}
                className="bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-700 hover:to-rose-700"
              >
                <Plus size={16} className="mr-2" />
                发布救援信息
              </Button>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-4 max-w-2xl mx-auto">
              {posts.map((post, index) => (
                <motion.div
                  key={post.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                  onClick={() => setSelectedPost(post)}
                >
                  <RescueCard post={post} />
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </div>

      <button
        onClick={() => setShowCreate(true)}
        className="fixed bottom-24 right-6 w-14 h-14 bg-gradient-to-br from-red-600 to-rose-600 text-white rounded-full shadow-lg hover:shadow-xl transition-all flex items-center justify-center"
      >
        <Plus size={28} />
      </button>

      <CreateRescuePost
        open={showCreate}
        onClose={() => setShowCreate(false)}
        onSubmit={handleCreatePost}
      />

      <RescueDetail
        post={selectedPost}
        isAdmin={isAdmin}
        onClose={() => setSelectedPost(null)}
        onStatusUpdate={(status, wechatQR) => {
          if (selectedPost) {
            const updatedPost = { ...selectedPost, status, wechatQR: wechatQR || selectedPost.wechatQR };
            const updatedPosts = posts.map(p => p.id === selectedPost.id ? updatedPost : p);
            setPosts(updatedPosts);
            setAllPosts(updatedPosts);
            savePostsToStorage(updatedPosts);
            setSelectedPost(updatedPost);
          }
        }}
        onPostUpdate={(updatedPost) => {
          if (selectedPost) {
            const updatedPosts = posts.map(p => p.id === updatedPost.id ? updatedPost : p);
            setPosts(updatedPosts);
            setAllPosts(updatedPosts);
            savePostsToStorage(updatedPosts);
            setSelectedPost(updatedPost);
          }
        }}
      />
    </>
  );
}
