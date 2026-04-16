import { useState } from 'react';
import { Dialog, DialogContent, DialogTitle, DialogDescription } from './ui/dialog';
import { Button } from './ui/button';
import { motion, AnimatePresence } from 'motion/react';
import { ChevronRight, X, ZoomIn, ChevronLeft } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';
import divisionImg from '../../imports/爱兔会分工.jpg';
import cooperationImg1 from '../../imports/爱兔会合作1.jpg';
import cooperationImg2 from '../../imports/爱兔会合作2.jpg';
import badgeImg from '../../imports/爱兔会徽章1.jpeg';

interface WelcomeModalProps {
  open: boolean;
  onClose: () => void;
}

const welcomeSteps = [
  {
    title: '🐰 欢迎来到爱兔会',
    content: '上海爱兔会是一个致力于流浪兔救助、保护和领养的公益组织。我们相信每一只兔兔都值得被爱，都应该拥有温暖的家。',
    highlights: [
      '🏥 专业医疗：与多家宠物医院合作',
      '🏡 寄养网络：提供温暖的临时家园',
      '💝 科学领养：严格筛选，负责到底',
      '📢 科普宣传：传播正确养兔知识'
    ],
    images: [badgeImg],
    canZoom: false,
  },
  {
    title: '👥 组内成员分工',
    content: '我们的团队专业而有爱，每个小组都在为兔兔的幸福而努力。从救助到领养，我们提供全流程的专业服务。点击图片可放大查看详情。',
    highlights: [
      '救助侧：现场救援、医疗协调、资源统筹、寄养安顿',
      '财务侧：救助兔兔、义卖',
      '领养侧：领养审核、家庭回访、档案管理',
      '宣传侧：新媒体运营、内容创作'
    ],
    images: [divisionImg],
    canZoom: true,
  },
  {
    title: '🤝 合作伙伴',
    content: '感谢我们的合作伙伴提供医疗支持、宠物用品和专业咨询。共同为兔兔的福祉而努力！点击图片可放大查看，左右滑动查看更多。',
    highlights: [
      '🏥 诺瓦宠物医院：提供优惠医疗服务',
      '🏥 河畔流浪动物体检福利',
      '🏥 内博虎流浪动物体检福利',
      '💼 多家合作机构：资源共享与互助'
    ],
    images: [cooperationImg1, cooperationImg2],
    canZoom: true,
  },
];

export default function WelcomeModal({ open, onClose }: WelcomeModalProps) {
  const [currentStep, setCurrentStep] = useState(0);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [isImageZoomed, setIsImageZoomed] = useState(false);

  const handleNext = () => {
    if (currentStep < welcomeSteps.length - 1) {
      setCurrentStep(currentStep + 1);
      setCurrentImageIndex(0);
    } else {
      onClose();
    }
  };

  const handlePrev = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
      setCurrentImageIndex(0);
    }
  };

  const step = welcomeSteps[currentStep];

  const handleNextImage = () => {
    if (currentImageIndex < step.images.length - 1) {
      setCurrentImageIndex(currentImageIndex + 1);
    }
  };

  const handlePrevImage = () => {
    if (currentImageIndex > 0) {
      setCurrentImageIndex(currentImageIndex - 1);
    }
  };

  return (
    <>
      <Dialog open={open} onOpenChange={onClose}>
        <DialogContent className="max-w-md p-0 overflow-hidden bg-gradient-to-br from-red-50 via-rose-50 to-pink-50 border-2 border-red-200" showClose={false}>
          <DialogTitle className="sr-only">{step.title}</DialogTitle>
          <DialogDescription className="sr-only">{step.content}</DialogDescription>

        <button
          onClick={onClose}
          className="absolute top-4 right-4 z-10 p-2 rounded-full bg-white/80 hover:bg-white transition-colors"
        >
          <X size={20} className="text-gray-600" />
        </button>

        <AnimatePresence mode="wait">
          <motion.div
            key={currentStep}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.4 }}
            className="p-6 pt-12"
          >
            <div className="relative mb-6">
              <div
                className={`aspect-[4/3] rounded-2xl overflow-hidden shadow-lg bg-white ${
                  step.canZoom ? 'cursor-pointer hover:shadow-xl transition-shadow' : ''
                }`}
                onClick={() => step.canZoom && setIsImageZoomed(true)}
              >
                <img
                  src={step.images[currentImageIndex]}
                  alt={step.title}
                  className="w-full h-full object-contain"
                />
                {step.canZoom && (
                  <div className="absolute bottom-3 right-3 bg-black/60 text-white px-2 py-1 rounded-lg text-xs flex items-center gap-1">
                    <ZoomIn size={14} />
                    点击放大
                  </div>
                )}
              </div>

              {/* 图片轮播控制 */}
              {step.images.length > 1 && (
                <>
                  {currentImageIndex > 0 && (
                    <button
                      onClick={handlePrevImage}
                      className="absolute left-2 top-1/2 -translate-y-1/2 w-8 h-8 bg-white/90 rounded-full flex items-center justify-center shadow-md hover:bg-white transition-colors"
                    >
                      <ChevronLeft size={20} className="text-gray-700" />
                    </button>
                  )}
                  {currentImageIndex < step.images.length - 1 && (
                    <button
                      onClick={handleNextImage}
                      className="absolute right-2 top-1/2 -translate-y-1/2 w-8 h-8 bg-white/90 rounded-full flex items-center justify-center shadow-md hover:bg-white transition-colors"
                    >
                      <ChevronRight size={20} className="text-gray-700" />
                    </button>
                  )}

                  {/* 图片指示器 */}
                  <div className="flex justify-center gap-1.5 mt-3">
                    {step.images.map((_, index) => (
                      <button
                        key={index}
                        onClick={() => setCurrentImageIndex(index)}
                        className={`h-1.5 rounded-full transition-all ${
                          index === currentImageIndex
                            ? 'w-6 bg-red-500'
                            : 'w-1.5 bg-red-200'
                        }`}
                      />
                    ))}
                  </div>
                </>
              )}
            </div>

            <h2 className="text-2xl font-bold text-red-800 mb-4" aria-hidden="true">{step.title}</h2>

            <p className="text-gray-700 leading-relaxed mb-4" aria-hidden="true">{step.content}</p>

            {step.highlights && (
              <div className="space-y-2 mb-6">
                {step.highlights.map((highlight, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.1 }}
                    className="flex items-center gap-2 text-sm text-red-700 bg-white/60 rounded-lg px-3 py-2"
                  >
                    <div className="w-1.5 h-1.5 rounded-full bg-red-500" />
                    <span className="font-medium">{highlight}</span>
                  </motion.div>
                ))}
              </div>
            )}

            <div className="flex items-center justify-between mt-6">
              <div className="flex gap-2">
                {welcomeSteps.map((_, index) => (
                  <div
                    key={index}
                    className={`h-2 rounded-full transition-all ${
                      index === currentStep
                        ? 'w-8 bg-red-500'
                        : 'w-2 bg-red-200'
                    }`}
                  />
                ))}
              </div>

              <div className="flex gap-2">
                {currentStep > 0 && (
                  <Button
                    variant="outline"
                    onClick={handlePrev}
                    className="border-red-300 hover:bg-red-50"
                  >
                    上一步
                  </Button>
                )}
                <Button
                  onClick={handleNext}
                  className="bg-gradient-to-r from-red-600 to-rose-600 hover:from-pink-600 hover:to-orange-600 text-white"
                >
                  {currentStep < welcomeSteps.length - 1 ? (
                    <>
                      下一步
                      <ChevronRight size={16} className="ml-1" />
                    </>
                  ) : (
                    '开始使用'
                  )}
                </Button>
              </div>
            </div>
          </motion.div>
        </AnimatePresence>
      </DialogContent>
    </Dialog>

    {/* 图片放大Dialog */}
    <Dialog open={isImageZoomed} onOpenChange={setIsImageZoomed}>
      <DialogContent className="max-w-4xl w-[95vw] h-[90vh] p-0 overflow-hidden bg-black/95">
        <DialogTitle className="sr-only">查看大图</DialogTitle>
        <DialogDescription className="sr-only">放大查看图片详情</DialogDescription>

        <button
          onClick={() => setIsImageZoomed(false)}
          className="absolute top-4 right-4 z-10 p-2 rounded-full bg-white/20 hover:bg-white/30 transition-colors"
        >
          <X size={24} className="text-white" />
        </button>

        <div className="relative w-full h-full flex items-center justify-center p-4">
          <img
            src={step.images[currentImageIndex]}
            alt={step.title}
            className="max-w-full max-h-full object-contain"
          />

          {/* 放大模式下的图片轮播 */}
          {step.images.length > 1 && (
            <>
              {currentImageIndex > 0 && (
                <button
                  onClick={handlePrevImage}
                  className="absolute left-4 top-1/2 -translate-y-1/2 w-12 h-12 bg-white/20 hover:bg-white/30 rounded-full flex items-center justify-center transition-colors"
                >
                  <ChevronLeft size={28} className="text-white" />
                </button>
              )}
              {currentImageIndex < step.images.length - 1 && (
                <button
                  onClick={handleNextImage}
                  className="absolute right-4 top-1/2 -translate-y-1/2 w-12 h-12 bg-white/20 hover:bg-white/30 rounded-full flex items-center justify-center transition-colors"
                >
                  <ChevronRight size={28} className="text-white" />
                </button>
              )}

              {/* 图片指示器 */}
              <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-2">
                {step.images.map((_, index) => (
                  <button
                    key={index}
                    onClick={() => setCurrentImageIndex(index)}
                    className={`h-2 rounded-full transition-all ${
                      index === currentImageIndex
                        ? 'w-8 bg-white'
                        : 'w-2 bg-white/50'
                    }`}
                  />
                ))}
              </div>
            </>
          )}
        </div>
      </DialogContent>
    </Dialog>
  </>
  );
}
