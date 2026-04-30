import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Heart, MapPin, Calendar, User, ChevronDown } from 'lucide-react';
import { RescuePost } from '../rescue/RescueTab';

interface RabbitStorybookProps {
  posts: RescuePost[];
}

export default function RabbitStorybook({ posts }: RabbitStorybookProps) {
  return (
    <div className="space-y-6">
      <div className="text-center mb-8">
        <h2 className="text-2xl font-bold text-gray-800 mb-2">兔兔故事书</h2>
        <p className="text-gray-600">记录每一只兔兔的救援之路</p>
      </div>

      {posts.length === 0 ? (
        <div className="text-center py-12 text-gray-500">
          <p>暂无救援故事</p>
        </div>
      ) : (
        posts.map((post, index) => (
          <StoryCard key={post.id} post={post} index={index} />
        ))
      )}
    </div>
  );
}

function useImageOrientation(src: string) {
  const [isPortrait, setIsPortrait] = useState<boolean | null>(null);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const img = new Image();
    img.src = src;
    img.onload = () => {
      setIsPortrait(img.naturalHeight > img.naturalWidth);
    };
  }, [src]);

  return isPortrait;
}

function StoryCard({ post, index }: { post: RescuePost; index: number }) {
  const [isExpanded, setIsExpanded] = useState(false);
  const [needsExpand, setNeedsExpand] = useState(false);
  const [showScrollHint, setShowScrollHint] = useState(false);
  const textRef = useRef<HTMLParagraphElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const imageSrc = post.images[0] || 'https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?w=600';
  const isPortrait = useImageOrientation(imageSrc);

  useEffect(() => {
    if (textRef.current && containerRef.current) {
      const textHeight = textRef.current.scrollHeight;
      const containerHeight = containerRef.current.clientHeight;
      setNeedsExpand(textHeight > containerHeight);
    }
  }, [post.description]);

  useEffect(() => {
    const hasSeenHint = localStorage.getItem('rabbitStorybookScrollHint');
    if (hasSeenHint) {
      setShowScrollHint(false);
    }
  }, []);

  const handleExpand = () => {
    if (!isExpanded) {
      const hasSeenHint = localStorage.getItem('rabbitStorybookScrollHint');
      if (!hasSeenHint) {
        setShowScrollHint(true);
        localStorage.setItem('rabbitStorybookScrollHint', 'true');
        setTimeout(() => setShowScrollHint(false), 3000);
      }
    }
    setIsExpanded(!isExpanded);
  };

  if (isPortrait) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: index * 0.15 }}
        className="bg-white rounded-2xl overflow-hidden shadow-lg"
      >
        <div className="flex h-80 sm:h-96">
          <div className="relative w-2/5 sm:w-1/2 h-full overflow-hidden">
            <img
              src={imageSrc}
              alt={post.title}
              className="w-full h-full object-cover"
            />
            <div className="absolute top-3 right-3">
              <span className="px-3 py-1.5 rounded-full bg-white/90 backdrop-blur-sm text-sm font-medium text-purple-700 border border-purple-200">
                {post.status}
              </span>
            </div>
          </div>
          <div className="w-3/5 sm:w-1/2 flex flex-col p-4">
            <h3 className="text-lg font-bold text-gray-800 flex items-center gap-2 mb-3">
              <Heart size={18} className="text-red-400" />
              {post.title}
            </h3>
            <div className="space-y-2 text-sm mb-3">
              <div className="flex items-center gap-2 text-gray-600">
                <Calendar size={14} className="text-purple-500" />
                <span>{post.date}</span>
              </div>
              <div className="flex items-center gap-2 text-gray-600">
                <User size={14} className="text-purple-500" />
                <span>{post.organizer?.name || '爱兔会'}</span>
              </div>
              <div className="flex items-center gap-2 text-gray-600">
                <MapPin size={14} className="text-purple-500 flex-shrink-0" />
                <span>{post.location || '待补充'}</span>
              </div>
            </div>
            <div className="border-t pt-3 flex-1 flex flex-col min-h-0">
              <h4 className="font-semibold text-gray-800 mb-2 flex-shrink-0">救援故事</h4>
              <div
                ref={containerRef}
                className={`relative flex-1 min-h-0 ${isExpanded ? 'overflow-y-auto' : 'overflow-hidden'}`}
              >
                <AnimatePresence>
                  {showScrollHint && (
                    <motion.div
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                      className="absolute inset-x-0 bottom-4 flex flex-col items-center gap-1 pointer-events-none z-10"
                    >
                      <div className="w-8 h-12 rounded-full bg-gradient-to-b from-purple-500/40 to-transparent flex items-start justify-center pt-2">
                        <motion.div
                          animate={{ y: [0, 4, 0] }}
                          transition={{ duration: 1.2, repeat: Infinity, ease: "easeInOut" }}
                        >
                          <svg width="16" height="10" viewBox="0 0 16 10" fill="none">
                            <path d="M1 4L8 9L15 4" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                          </svg>
                        </motion.div>
                      </div>
                      <div className="w-8 h-12 rounded-full bg-gradient-to-t from-purple-500/40 to-transparent flex items-end justify-center pb-2">
                        <motion.div
                          animate={{ y: [0, -4, 0] }}
                          transition={{ duration: 1.2, repeat: Infinity, ease: "easeInOut" }}
                        >
                          <svg width="16" height="10" viewBox="0 0 16 10" fill="none">
                            <path d="M1 6L8 1L15 6" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                          </svg>
                        </motion.div>
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
                <p ref={textRef} className="text-gray-600 text-sm leading-relaxed">
                  {post.description}
                </p>
                {!isExpanded && needsExpand && (
                  <div className="absolute bottom-0 left-0 right-0 h-8 bg-gradient-to-t from-white to-transparent pointer-events-none" />
                )}
              </div>
              {needsExpand && (
                <button
                  onClick={handleExpand}
                  className="mt-1 text-purple-600 text-sm font-medium flex items-center gap-1 hover:text-purple-700 transition-colors flex-shrink-0"
                >
                  {isExpanded ? '收起' : '展开'}
                  <ChevronDown
                    size={14}
                    className={`transition-transform ${isExpanded ? 'rotate-180' : ''}`}
                  />
                </button>
              )}
            </div>
          </div>
        </div>
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 30 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.15 }}
      className="bg-white rounded-2xl overflow-hidden shadow-lg"
    >
      <div className="relative h-64 sm:h-72">
        <img
          src={imageSrc}
          alt={post.title}
          className="w-full h-full object-cover"
        />
        <div className="absolute top-3 right-3">
          <span className="px-3 py-1.5 rounded-full bg-white/90 backdrop-blur-sm text-sm font-medium text-purple-700 border border-purple-200">
            {post.status}
          </span>
        </div>
        <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/60 to-transparent p-4">
          <h3 className="text-xl font-bold text-white flex items-center gap-2">
            <Heart size={20} className="text-red-400" />
            {post.title}
          </h3>
        </div>
      </div>

      <div className="p-4 space-y-3">
        <div className="grid grid-cols-2 gap-3 text-sm">
          <div className="flex items-center gap-2 text-gray-600">
            <Calendar size={16} className="text-purple-500" />
            <span>{post.date}</span>
          </div>
          <div className="flex items-center gap-2 text-gray-600">
            <User size={16} className="text-purple-500" />
            <span>{post.organizer?.name || '爱兔会'}</span>
          </div>
          <div className="flex items-center gap-2 text-gray-600 col-span-2">
            <MapPin size={16} className="text-purple-500" />
            <span>{post.location || '待补充'}</span>
          </div>
        </div>

        <div className="border-t pt-3">
          <h4 className="font-semibold text-gray-800 mb-2">救援故事</h4>
          <div>
            <div
              className={`relative overflow-hidden transition-all duration-300 ${
                !isExpanded ? 'max-h-16' : 'max-h-48'
              }`}
            >
              <p className="text-gray-600 text-sm leading-relaxed">
                {post.description}
              </p>
              {!isExpanded && (
                <div className="absolute bottom-0 left-0 right-0 h-8 bg-gradient-to-t from-white to-transparent" />
              )}
            </div>
            <button
              onClick={() => setIsExpanded(!isExpanded)}
              className="mt-1 text-purple-600 text-sm font-medium flex items-center gap-1 hover:text-purple-700 transition-colors"
            >
              {isExpanded ? '收起' : '查看详情'}
              <ChevronDown
                size={16}
                className={`transition-transform ${isExpanded ? 'rotate-180' : ''}`}
              />
            </button>
          </div>
        </div>
      </div>
    </motion.div>
  );
}
