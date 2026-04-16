import { useState } from 'react';
import { Dialog, DialogContent, DialogTitle, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { Label } from '../ui/label';
import { X, Upload, Image as ImageIcon, Video } from 'lucide-react';
import { toast } from 'sonner';
import { EventData } from './EventDetail';

interface CreateEventDialogProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (event: Omit<EventData, 'id'>) => void;
}

export default function CreateEventDialog({ open, onClose, onSubmit }: CreateEventDialogProps) {
  const [eventType, setEventType] = useState<'past' | 'upcoming'>('upcoming');
  const [title, setTitle] = useState('');
  const [date, setDate] = useState('');
  const [location, setLocation] = useState('');
  const [description, setDescription] = useState('');
  const [participants, setParticipants] = useState('');
  const [posterImage, setPosterImage] = useState('');
  const [bannerImage, setBannerImage] = useState('');
  const [images, setImages] = useState<string[]>([]);
  const [videos, setVideos] = useState<string[]>([]);

  const handlePosterUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onloadend = () => {
      setPosterImage(reader.result as string);
    };
    reader.readAsDataURL(file);
  };

  const handleBannerUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onloadend = () => {
      setBannerImage(reader.result as string);
    };
    reader.readAsDataURL(file);
  };

  const handleImagesUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files) return;

    const fileArray = Array.from(files);
    fileArray.forEach((file) => {
      const reader = new FileReader();
      reader.onloadend = () => {
        setImages((prev) => [...prev, reader.result as string]);
      };
      reader.readAsDataURL(file);
    });
  };

  const removeImage = (index: number) => {
    setImages((prev) => prev.filter((_, i) => i !== index));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!title || !date || !location || !posterImage) {
      toast.error('请填写必填项', {
        description: '活动标题、时间、地点和海报图片为必填项',
      });
      return;
    }

    const newEvent: Omit<EventData, 'id'> = {
      title,
      date,
      location,
      image: posterImage,
      bannerImage: bannerImage || undefined,
      description: description || '暂无描述',
      type: eventType,
      participants: participants ? parseInt(participants) : undefined,
      images: images.length > 0 ? images : undefined,
      videos: videos.length > 0 ? videos : undefined,
    };

    onSubmit(newEvent);
    toast.success('活动创建成功！');

    // 重置表单
    setTitle('');
    setDate('');
    setLocation('');
    setDescription('');
    setParticipants('');
    setPosterImage('');
    setBannerImage('');
    setImages([]);
    setVideos([]);
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto" showClose={false}>
        <DialogTitle className="text-2xl font-bold text-red-800 flex items-center justify-between">
          <span>新增活动</span>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <X size={20} />
          </button>
        </DialogTitle>
        <DialogDescription className="text-sm text-gray-600">
          填写活动信息，创建新的线下活动
        </DialogDescription>

        <form onSubmit={handleSubmit} className="space-y-6 mt-4">
          {/* 活动类型 */}
          <div>
            <Label className="text-sm font-medium text-gray-700 mb-2 block">
              活动类型 <span className="text-red-500">*</span>
            </Label>
            <div className="flex gap-4">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="radio"
                  value="upcoming"
                  checked={eventType === 'upcoming'}
                  onChange={(e) => setEventType(e.target.value as 'upcoming')}
                  className="w-4 h-4 text-red-500"
                />
                <span className="text-sm text-gray-700">未来活动</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="radio"
                  value="past"
                  checked={eventType === 'past'}
                  onChange={(e) => setEventType(e.target.value as 'past')}
                  className="w-4 h-4 text-red-500"
                />
                <span className="text-sm text-gray-700">往期活动</span>
              </label>
            </div>
          </div>

          {/* 活动海报 */}
          <div>
            <Label className="text-sm font-medium text-gray-700 mb-2 block">
              活动海报（详情页展示） <span className="text-red-500">*</span>
            </Label>
            {posterImage ? (
              <div className="relative aspect-video rounded-lg overflow-hidden border border-gray-200 bg-gray-50">
                <img src={posterImage} alt="活动海报" className="w-full h-full object-contain" />
                <button
                  type="button"
                  onClick={() => setPosterImage('')}
                  className="absolute top-2 right-2 bg-black/50 hover:bg-black/70 rounded-full p-1 transition-colors"
                >
                  <X size={16} className="text-white" />
                </button>
              </div>
            ) : (
              <label className="border-2 border-dashed border-red-200 rounded-lg p-8 text-center hover:border-red-400 transition-colors cursor-pointer block">
                <input
                  type="file"
                  accept="image/*"
                  onChange={handlePosterUpload}
                  className="hidden"
                />
                <Upload size={32} className="mx-auto text-red-400 mb-2" />
                <p className="text-sm text-gray-600">点击上传活动海报</p>
              </label>
            )}
          </div>

          {/* 卡片背景图 */}
          <div>
            <Label className="text-sm font-medium text-gray-700 mb-2 block">
              卡片背景图（可选）
            </Label>
            <p className="text-xs text-gray-500 mb-2">用于活动卡片展示，建议使用可爱的插画或兔兔图片</p>
            {bannerImage ? (
              <div className="relative aspect-video rounded-lg overflow-hidden border border-gray-200 bg-gray-50">
                <img src={bannerImage} alt="卡片背景" className="w-full h-full object-cover" />
                <button
                  type="button"
                  onClick={() => setBannerImage('')}
                  className="absolute top-2 right-2 bg-black/50 hover:bg-black/70 rounded-full p-1 transition-colors"
                >
                  <X size={16} className="text-white" />
                </button>
              </div>
            ) : (
              <label className="border-2 border-dashed border-gray-200 rounded-lg p-6 text-center hover:border-red-300 transition-colors cursor-pointer block">
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleBannerUpload}
                  className="hidden"
                />
                <Upload size={24} className="mx-auto text-gray-400 mb-2" />
                <p className="text-sm text-gray-600">点击上传卡片背景图</p>
              </label>
            )}
          </div>

          {/* 活动标题 */}
          <div>
            <Label htmlFor="title" className="text-sm font-medium text-gray-700 mb-2 block">
              活动标题 <span className="text-red-500">*</span>
            </Label>
            <Input
              id="title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="例如：春日兔友百人聚"
              maxLength={50}
            />
          </div>

          {/* 活动时间 */}
          <div>
            <Label htmlFor="date" className="text-sm font-medium text-gray-700 mb-2 block">
              活动时间 <span className="text-red-500">*</span>
            </Label>
            <Input
              id="date"
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
            />
          </div>

          {/* 活动地点 */}
          <div>
            <Label htmlFor="location" className="text-sm font-medium text-gray-700 mb-2 block">
              活动地点 <span className="text-red-500">*</span>
            </Label>
            <Input
              id="location"
              value={location}
              onChange={(e) => setLocation(e.target.value)}
              placeholder="例如：市中心6600㎡超大场馆"
            />
          </div>

          {/* 参与人数（仅往期活动） */}
          {eventType === 'past' && (
            <div>
              <Label htmlFor="participants" className="text-sm font-medium text-gray-700 mb-2 block">
                参与人数
              </Label>
              <Input
                id="participants"
                type="number"
                value={participants}
                onChange={(e) => setParticipants(e.target.value)}
                placeholder="例如：156"
              />
            </div>
          )}

          {/* 活动描述 */}
          <div>
            <Label htmlFor="description" className="text-sm font-medium text-gray-700 mb-2 block">
              活动描述
            </Label>
            <Textarea
              id="description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="详细描述活动内容、亮点等..."
              rows={4}
            />
          </div>

          {/* 活动图片 */}
          <div>
            <Label className="text-sm font-medium text-gray-700 mb-2 block">
              活动图片（可选）
            </Label>
            {images.length > 0 && (
              <div className="grid grid-cols-3 gap-2 mb-3">
                {images.map((img, index) => (
                  <div key={index} className="relative aspect-square rounded-lg overflow-hidden border border-gray-200 bg-gray-50">
                    <img src={img} alt={`活动图片 ${index + 1}`} className="w-full h-full object-contain" />
                    <button
                      type="button"
                      onClick={() => removeImage(index)}
                      className="absolute top-1 right-1 bg-black/50 hover:bg-black/70 rounded-full p-1 transition-colors"
                    >
                      <X size={14} className="text-white" />
                    </button>
                  </div>
                ))}
              </div>
            )}
            <label className="border-2 border-dashed border-gray-200 rounded-lg p-6 text-center hover:border-red-300 transition-colors cursor-pointer block">
              <input
                type="file"
                accept="image/*"
                multiple
                onChange={handleImagesUpload}
                className="hidden"
              />
              <ImageIcon size={24} className="mx-auto text-gray-400 mb-2" />
              <p className="text-sm text-gray-600">点击上传活动图片（已上传 {images.length} 张）</p>
            </label>
          </div>

          {/* 提交按钮 */}
          <div className="flex gap-3 pt-4">
            <Button type="button" variant="outline" onClick={onClose} className="flex-1">
              取消
            </Button>
            <Button
              type="submit"
              className="flex-1 bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-700 hover:to-rose-700"
            >
              创建活动
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
