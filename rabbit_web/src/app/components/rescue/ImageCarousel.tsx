import { useState } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface ImageCarouselProps {
  images: string[];
  alt: string;
  badge?: string; // 可选的标签，如 "永远的女明星👑"
}

export default function ImageCarousel({ images, alt, badge }: ImageCarouselProps) {
  const [currentIndex, setCurrentIndex] = useState(0);

  if (!images || images.length === 0) {
    return (
      <div className="w-full h-64 bg-gray-100 flex items-center justify-center rounded-xl">
        <span className="text-gray-400">暂无图片</span>
      </div>
    );
  }

  const goToPrevious = (e: React.MouseEvent) => {
    e.stopPropagation();
    setCurrentIndex((prev) => (prev === 0 ? images.length - 1 : prev - 1));
  };

  const goToNext = (e: React.MouseEvent) => {
    e.stopPropagation();
    setCurrentIndex((prev) => (prev === images.length - 1 ? 0 : prev + 1));
  };

  return (
    <div className="relative w-full overflow-hidden rounded-xl bg-gradient-to-br from-gray-50 to-gray-100">
      {/* 标签 */}
      {badge && (
        <div className="absolute top-3 left-3 z-10 px-3 py-1.5 bg-gradient-to-r from-yellow-400 to-orange-400 text-white text-sm font-semibold rounded-full shadow-lg">
          {badge}
        </div>
      )}

      <div
        className="flex transition-transform duration-300 ease-out"
        style={{ transform: `translateX(-${currentIndex * 100}%)` }}
      >
        {images.map((image, index) => (
          <img
            key={index}
            src={image}
            alt={`${alt} - ${index + 1}`}
            className="w-full max-h-[400px] object-contain flex-shrink-0"
            onError={(e) => {
              (e.target as HTMLImageElement).src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 400 400"%3E%3Crect fill="%23f3f4f6" width="400" height="400"/%3E%3Ctext fill="%239ca3af" font-family="sans-serif" font-size="24" x="50%25" y="50%25" text-anchor="middle" dy=".3em"%3E图片加载失败%3C/text%3E%3C/svg%3E';
            }}
          />
        ))}
      </div>

      {images.length > 1 && (
        <>
          <button
            onClick={goToPrevious}
            className="absolute left-2 top-1/2 -translate-y-1/2 w-8 h-8 bg-white/80 hover:bg-white rounded-full shadow-md flex items-center justify-center transition-colors"
            aria-label="上一张"
          >
            <ChevronLeft size={18} className="text-gray-700" />
          </button>
          <button
            onClick={goToNext}
            className="absolute right-2 top-1/2 -translate-y-1/2 w-8 h-8 bg-white/80 hover:bg-white rounded-full shadow-md flex items-center justify-center transition-colors"
            aria-label="下一张"
          >
            <ChevronRight size={18} className="text-gray-700" />
          </button>

          <div className="absolute bottom-3 left-1/2 -translate-x-1/2 flex gap-1.5">
            {images.map((_, index) => (
              <button
                key={index}
                onClick={(e) => {
                  e.stopPropagation();
                  setCurrentIndex(index);
                }}
                className={`w-1.5 h-1.5 rounded-full transition-all ${
                  index === currentIndex
                    ? 'bg-white w-4'
                    : 'bg-white/50 hover:bg-white/80'
                }`}
                aria-label={`切换到第${index + 1}张`}
              />
            ))}
          </div>
        </>
      )}
    </div>
  );
}
