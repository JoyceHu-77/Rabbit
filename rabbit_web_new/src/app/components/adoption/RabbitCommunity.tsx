import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Plus, Heart, MessageCircle, Trash2, Image as ImageIcon } from 'lucide-react';
import { Button } from '../ui/button';
import CreateRabbitPost from './CreateRabbitPost';
import ImageCarousel from '../rescue/ImageCarousel';
import { toast } from 'sonner';

export interface RabbitPost {
  id: string;
  authorName: string;
  title: string;
  content: string;
  images: string[];
  createdAt: string;
  likes: number;
  likedByUser: boolean;
}

// 从 localStorage 加载帖子数据
const loadSavedPosts = (): RabbitPost[] => {
  try {
    const saved = localStorage.getItem('savedRabbitCommunityPosts');
    if (saved) {
      return JSON.parse(saved);
    }
  } catch (e) {
    console.error('Failed to load saved posts:', e);
  }
  return [];
};

// 保存帖子数据到 localStorage
const savePostsToStorage = (posts: RabbitPost[]) => {
  try {
    localStorage.setItem('savedRabbitCommunityPosts', JSON.stringify(posts));
  } catch (e) {
    console.error('Failed to save posts:', e);
  }
};

// 格式化日期
const formatDate = (dateStr: string): string => {
  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

  if (diffDays === 0) {
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    if (diffHours === 0) {
      const diffMins = Math.floor(diffMs / (1000 * 60));
      return diffMins <= 1 ? '刚刚' : `${diffMins}分钟前`;
    }
    return `${diffHours}小时前`;
  }
  if (diffDays === 1) return '昨天';
  if (diffDays < 7) return `${diffDays}天前`;
  if (diffDays < 30) return `${Math.floor(diffDays / 7)}周前`;
  return `${Math.floor(diffDays / 30)}个月前`;
};

interface RabbitCommunityProps {
  isAdmin: boolean;
}

export default function RabbitCommunity({ isAdmin }: RabbitCommunityProps) {
  const [posts, setPosts] = useState<RabbitPost[]>([]);
  const [showCreate, setShowCreate] = useState(false);
  const [expandedPostId, setExpandedPostId] = useState<string | null>(null);

  useEffect(() => {
    setPosts(loadSavedPosts());
  }, []);

  const handleCreatePost = (newPost: Omit<RabbitPost, 'id' | 'createdAt' | 'likes' | 'likedByUser'>) => {
    const post: RabbitPost = {
      ...newPost,
      id: `RC${Date.now()}`,
      createdAt: new Date().toISOString(),
      likes: 0,
      likedByUser: false,
    };
    const updatedPosts = [post, ...posts];
    setPosts(updatedPosts);
    savePostsToStorage(updatedPosts);
    setShowCreate(false);
    toast.success('发布成功！');
  };

  const handleDeletePost = (postId: string) => {
    const updatedPosts = posts.filter(p => p.id !== postId);
    setPosts(updatedPosts);
    savePostsToStorage(updatedPosts);
    toast.success('删除成功');
  };

  const handleLike = (postId: string) => {
    const updatedPosts = posts.map(p => {
      if (p.id === postId) {
        return {
          ...p,
          likes: p.likedByUser ? p.likes - 1 : p.likes + 1,
          likedByUser: !p.likedByUser,
        };
      }
      return p;
    });
    setPosts(updatedPosts);
    savePostsToStorage(updatedPosts);
  };

  return (
    <div className="space-y-6">
      {/* 标题区 */}
      <div className="text-center">
        <h2 className="text-2xl font-bold text-gray-800 mb-2">爱兔社区</h2>
        <p className="text-gray-600">晒出你家宝贝的可爱瞬间</p>
      </div>

      {/* 说明卡片 */}
      <div className="bg-gradient-to-br from-purple-50 to-pink-50 rounded-xl p-5 border border-purple-200">
        <h3 className="font-semibold text-gray-800 mb-2 flex items-center gap-2">
          <Heart size={18} className="text-red-500" />
          分享你家兔兔的故事
        </h3>
        <p className="text-sm text-gray-600 leading-relaxed">
          无论是从爱兔会领养的兔兔，还是从宠物店买来的宝贝，只要是自家的兔兔都可以分享！
          这里是兔爸兔妈们的交流天地，快来晒出你家宝贝的可爱瞬间吧~
        </p>
      </div>

      {/* 空状态 */}
      {posts.length === 0 ? (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-2xl p-10 shadow-md text-center"
        >
          <div className="text-7xl mb-4">🐰</div>
          <h3 className="text-xl font-bold text-gray-800 mb-2">还没有人分享</h3>
          <p className="text-gray-500 mb-6">快来分享你家兔兔的第一张萌照吧！</p>
          <Button
            onClick={() => setShowCreate(true)}
            className="bg-gradient-to-r from-red-500 to-rose-500 hover:from-red-600 hover:to-rose-600"
          >
            <Plus size={18} className="mr-2" />
            发布第一篇
          </Button>
        </motion.div>
      ) : (
        <>
          {/* 帖子列表 */}
          <div className="space-y-4">
            {posts.map((post, index) => (
              <motion.div
                key={post.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.05 }}
                className="bg-white rounded-2xl shadow-md overflow-hidden"
              >
                {/* 帖子头部 */}
                <div className="p-4 pb-3">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-gradient-to-br from-red-100 to-rose-100 flex items-center justify-center">
                        <span className="text-lg">🐰</span>
                      </div>
                      <div>
                        <p className="font-semibold text-gray-800">{post.authorName}</p>
                        <p className="text-xs text-gray-400">{formatDate(post.createdAt)}</p>
                      </div>
                    </div>
                    {/* 删除按钮 - 仅管理员可见 */}
                    {isAdmin && (
                      <button
                        onClick={() => handleDeletePost(post.id)}
                        className="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-full transition-colors"
                      >
                        <Trash2 size={18} />
                      </button>
                    )}
                  </div>

                  {/* 标题 */}
                  <h3 className="font-bold text-gray-800 text-lg mb-2">{post.title}</h3>

                  {/* 内容 */}
                  <p className={`text-gray-600 text-sm leading-relaxed ${expandedPostId === post.id ? '' : 'line-clamp-3'}`}>
                    {post.content}
                  </p>
                  {post.content.length > 100 && expandedPostId !== post.id && (
                    <button
                      onClick={() => setExpandedPostId(post.id)}
                      className="text-red-500 text-sm mt-1 hover:underline"
                    >
                     展开全文
                    </button>
                  )}
                  {expandedPostId === post.id && (
                    <button
                      onClick={() => setExpandedPostId(null)}
                      className="text-red-500 text-sm mt-1 hover:underline"
                    >
                      收起
                    </button>
                  )}
                </div>

                {/* 图片展示 */}
                {post.images.length > 0 && (
                  <div className="px-4 pb-3">
                    {post.images.length === 1 ? (
                      <div className="rounded-xl overflow-hidden">
                        <img
                          src={post.images[0]}
                          alt={post.title}
                          className="w-full max-h-80 object-contain bg-gray-50"
                        />
                      </div>
                    ) : (
                      <ImageCarousel images={post.images} />
                    )}
                  </div>
                )}

                {/* 互动栏 */}
                <div className="px-4 py-3 border-t border-gray-100 flex items-center gap-4">
                  <button
                    onClick={() => handleLike(post.id)}
                    className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full transition-colors ${
                      post.likedByUser
                        ? 'bg-red-50 text-red-500'
                        : 'hover:bg-gray-100 text-gray-500'
                    }`}
                  >
                    <Heart
                      size={18}
                      className={post.likedByUser ? 'fill-current' : ''}
                    />
                    <span className="text-sm">{post.likes || ''}</span>
                  </button>
                  <div className="flex items-center gap-1.5 px-3 py-1.5 text-gray-400">
                    <MessageCircle size={18} />
                    <span className="text-sm">评论</span>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          {/* 新增按钮 */}
          <Button
            onClick={() => setShowCreate(true)}
            className="fixed bottom-24 right-6 w-14 h-14 bg-gradient-to-br from-red-500 to-rose-500 hover:from-red-600 hover:to-rose-600 text-white rounded-full shadow-lg hover:shadow-xl transition-all flex items-center justify-center"
          >
            <Plus size={28} />
          </Button>
        </>
      )}

      {/* 创建帖子弹窗 */}
      <CreateRabbitPost
        open={showCreate}
        onClose={() => setShowCreate(false)}
        onSubmit={handleCreatePost}
      />
    </div>
  );
}
