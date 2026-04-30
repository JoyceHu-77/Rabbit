import { useState } from 'react';
import { motion } from 'motion/react';
import { Plus, Package, RefreshCw, Gift } from 'lucide-react';
import { Button } from '../ui/button';
import { toast } from 'sonner';
import CreateDonationPost from './CreateDonationPost';

interface DonationTabProps {
  isAdmin: boolean;
}

interface DonationPost {
  id: string;
  title: string;
  description: string;
  image: string;
  type: '捐赠' | '置换';
  target: '爱兔会' | '共享';
  status: '待领取' | '已完成';
  contact: {
    name: string;
    phone: string;
  };
  date: string;
}

const mockPosts: DonationPost[] = [
  {
    id: 'D001',
    title: '兔粮500g × 3包',
    description: '多买了几包兔粮，家里兔兔吃不完，希望能帮助到需要的兔兔',
    image: 'https://images.unsplash.com/photo-1578164252938-1da0cd4caa30?w=400',
    type: '捐赠',
    target: '共享',
    status: '待领取',
    contact: { name: '李女士', phone: '138****1234' },
    date: '2026-04-10',
  },
  {
    id: 'D002',
    title: '兔笼 + 饮水器',
    description: '九成新兔笼，配饮水器和食盆，可置换其他用品或捐赠',
    image: 'https://images.unsplash.com/photo-1695826809879-6bc04b19e56d?w=400',
    type: '置换',
    target: '共享',
    status: '待领取',
    contact: { name: '王先生', phone: '139****5678' },
    date: '2026-04-09',
  },
  {
    id: 'D003',
    title: '干草 2kg',
    description: '指定捐赠给爱兔会，用于救助兔兔',
    image: 'https://images.unsplash.com/photo-1695826809742-b3e2e7483efd?w=400',
    type: '捐赠',
    target: '爱兔会',
    status: '已完成',
    contact: { name: '张女士', phone: '136****9012' },
    date: '2026-04-08',
  },
  {
    id: 'D004',
    title: '兔兔玩具套装',
    description: '咬咬球、草编玩具等，家里兔兔不喜欢，可以置换其他玩具',
    image: 'https://images.unsplash.com/photo-1564326140-fa771b2c0c5d?w=400',
    type: '置换',
    target: '共享',
    status: '待领取',
    contact: { name: '陈女士', phone: '137****3456' },
    date: '2026-04-07',
  },
];

export default function DonationTab({ isAdmin }: DonationTabProps) {
  const [posts, setPosts] = useState<DonationPost[]>(mockPosts);
  const [showCreate, setShowCreate] = useState(false);

  const handleClaim = (post: DonationPost) => {
    if (post.target === '爱兔会') {
      toast.info('该物资已指定捐赠给爱兔会');
    } else {
      toast.success('已提交领取申请', {
        description: '您可以联系发布者进行交接',
      });
    }
  };

  const handleExchange = (post: DonationPost) => {
    toast.success('已提交置换申请', {
      description: '您可以联系发布者协商置换事宜',
    });
  };

  const handleCreatePost = (newPost: Omit<DonationPost, 'id' | 'date'>) => {
    const post: DonationPost = {
      ...newPost,
      id: `D${String(posts.length + 1).padStart(3, '0')}`,
      date: new Date().toISOString().split('T')[0],
    };
    setPosts([post, ...posts]);
    setShowCreate(false);
  };

  return (
    <>
      <div className="min-h-screen">
        <div className="bg-gradient-to-br from-rose-600 to-red-600 text-white px-6 py-8">
          <h1 className="text-3xl font-bold mb-2">物资捐换</h1>
          <p className="text-white/90 text-sm">分享爱心，物尽其用</p>
        </div>

        <div className="px-4 py-6">
          <div className="grid grid-cols-2 gap-4 max-w-2xl mx-auto">
            {posts.map((post, index) => (
              <motion.div
                key={post.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                className="bg-white rounded-xl overflow-hidden shadow-md hover:shadow-lg transition-shadow"
              >
                <div className="aspect-square relative">
                  <img
                    src={post.image}
                    alt={post.title}
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute top-2 left-2 flex gap-2">
                    <span
                      className={`px-2 py-1 rounded-full text-xs font-medium ${
                        post.type === '捐赠'
                          ? 'bg-green-500 text-white'
                          : 'bg-blue-500 text-white'
                      }`}
                    >
                      {post.type}
                    </span>
                    {post.status === '已完成' && (
                      <span className="px-2 py-1 rounded-full bg-gray-500 text-white text-xs font-medium">
                        {post.status}
                      </span>
                    )}
                  </div>
                  {post.target === '爱兔会' && (
                    <div className="absolute top-2 right-2">
                      <Gift size={20} className="text-white drop-shadow-lg" />
                    </div>
                  )}
                </div>

                <div className="p-3">
                  <h3 className="font-semibold text-sm text-gray-800 mb-2 line-clamp-1">
                    {post.title}
                  </h3>

                  <p className="text-xs text-gray-600 mb-3 line-clamp-2">
                    {post.description}
                  </p>

                  <div className="text-xs text-gray-500 mb-3">
                    <p>联系人：{post.contact.name}</p>
                    <p>联系方式：{post.contact.phone}</p>
                  </div>

                  {post.status !== '已完成' && post.target !== '爱兔会' && (
                    <div className="flex gap-2">
                      {post.type === '捐赠' ? (
                        <Button
                          size="sm"
                          onClick={() => handleClaim(post)}
                          className="flex-1 text-xs bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600"
                        >
                          <Package size={14} className="mr-1" />
                          领取
                        </Button>
                      ) : (
                        <Button
                          size="sm"
                          onClick={() => handleExchange(post)}
                          className="flex-1 text-xs bg-gradient-to-r from-blue-500 to-cyan-500 hover:from-blue-600 hover:to-cyan-600"
                        >
                          <RefreshCw size={14} className="mr-1" />
                          置换
                        </Button>
                      )}
                    </div>
                  )}

                  {post.target === '爱兔会' && (
                    <div className="text-xs text-orange-600 font-medium">
                      已指定捐赠给爱兔会 ❤️
                    </div>
                  )}
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>

      <button
        onClick={() => setShowCreate(true)}
        className="fixed bottom-24 right-6 w-14 h-14 bg-gradient-to-br from-rose-600 to-red-600 text-white rounded-full shadow-lg hover:shadow-xl transition-all flex items-center justify-center"
      >
        <Plus size={28} />
      </button>

      <CreateDonationPost
        open={showCreate}
        onClose={() => setShowCreate(false)}
        onSubmit={handleCreatePost}
      />
    </>
  );
}
