import { useState, useRef } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { X, Upload, MapPin, Calendar, AlertCircle } from 'lucide-react';
import { RescuePost } from './RescueTab';
import { toast } from 'sonner';

interface CreateRescuePostProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (post: Omit<RescuePost, 'id'>) => void;
}

// 中文输入校验函数
const validateChineseText = (text: string): { valid: boolean; message: string } => {
  // 检查是否包含非中文、非中文标点符号
  const chinesePattern = /^[\u4e00-\u9fa5\u3000-\u303f\uff00-\uffef\s，。、！？；：""''（）【】《》\d\w]*$/;
  // 污言秽语关键词
  const inappropriateWords = ['傻逼', '智障', '脑残', '废物', '垃圾', '操', '艹', '他妈', '他妈', '你妈', '死全家'];

  if (!chinesePattern.test(text)) {
    return { valid: false, message: '请输入中文文字' };
  }

  for (const word of inappropriateWords) {
    if (text.includes(word)) {
      return { valid: false, message: '请输入文明用语' };
    }
  }

  return { valid: true, message: '' };
};

// 发现人名称校验（中英文）
const validateFinderName = (name: string): boolean => {
  const pattern = /^[\u4e00-\u9fa5a-zA-Z\s]+$/;
  return pattern.test(name);
};

// 发现人联系方式校验（中英文、数字）
const validateContact = (contact: string): boolean => {
  const pattern = /^[\u4e00-\u9fa5a-zA-Z0-9\s\-_]+$/;
  return pattern.test(contact);
};

export default function CreateRescuePost({ open, onClose, onSubmit }: CreateRescuePostProps) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [location, setLocation] = useState('');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [finderName, setFinderName] = useState('');
  const [finderContact, setFinderContact] = useState('');
  const [isPublic, setIsPublic] = useState(false);
  const [images, setImages] = useState<string[]>([]);

  // 健康状态
  const [healthStatus, setHealthStatus] = useState<'健康' | '仍有伤痛' | '未知'>('未知');
  // 绝育状态
  const [sterilizedStatus, setSterilizedStatus] = useState<'已绝育' | '未绝育' | '未知'>('未知');

  // 校验错误状态
  const [descriptionError, setDescriptionError] = useState('');
  const [finderNameError, setFinderNameError] = useState('');
  const [finderContactError, setFinderContactError] = useState('');

  // 草稿箱
  const [savedDraft, setSavedDraft] = useState<any>(null);

  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files) return;

    const fileArray = Array.from(files);
    if (images.length + fileArray.length > 10) {
      toast.error('最多只能上传10张图片');
      return;
    }

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

  const handleDescriptionBlur = () => {
    if (description.trim()) {
      const result = validateChineseText(description);
      if (!result.valid) {
        setDescriptionError(result.message);
      } else {
        setDescriptionError('');
      }
    }
  };

  const handleFinderNameChange = (value: string) => {
    setFinderName(value);
    if (value && !validateFinderName(value)) {
      setFinderNameError('请输入中英文名称');
    } else {
      setFinderNameError('');
    }
  };

  const handleFinderContactChange = (value: string) => {
    setFinderContact(value);
    if (value && !validateContact(value)) {
      setFinderContactError('请输入正确的联系方式');
    } else {
      setFinderContactError('');
    }
  };

  const saveDraft = () => {
    const draft = {
      title,
      description,
      location,
      date,
      finderName,
      finderContact,
      isPublic,
      images,
      healthStatus,
      sterilizedStatus,
    };
    localStorage.setItem('rescueDraft', JSON.stringify(draft));
    setSavedDraft(draft);
  };

  const loadDraft = () => {
    const draft = localStorage.getItem('rescueDraft');
    if (draft) {
      const parsed = JSON.parse(draft);
      setTitle(parsed.title || '');
      setDescription(parsed.description || '');
      setLocation(parsed.location || '');
      setDate(parsed.date || new Date().toISOString().split('T')[0]);
      setFinderName(parsed.finderName || '');
      setFinderContact(parsed.finderContact || '');
      setIsPublic(parsed.isPublic || false);
      setImages(parsed.images || []);
      setHealthStatus(parsed.healthStatus || '未知');
      setSterilizedStatus(parsed.sterilizedStatus || '未知');
      toast.success('已从草稿箱恢复');
    }
  };

  const handleSubmit = () => {
    // 校验必填项
    if (!title.trim()) {
      toast.error('请输入标题');
      return;
    }
    if (!description.trim()) {
      toast.error('请输入详细描述');
      return;
    }
    if (!location.trim()) {
      toast.error('请输入发现地点');
      return;
    }
    if (images.length === 0) {
      toast.error('请至少上传一张图片');
      return;
    }

    // 校验描述
    const descResult = validateChineseText(description);
    if (!descResult.valid) {
      setDescriptionError(descResult.message);
      toast.error('请输入正确的文字');
      return;
    }

    // 校验发现人名称
    if (finderName && !validateFinderName(finderName)) {
      setFinderNameError('请输入中英文名称');
      return;
    }

    // 校验联系方式
    if (finderContact && !validateContact(finderContact)) {
      setFinderContactError('请输入正确的联系方式');
      return;
    }

    const newPost: Omit<RescuePost, 'id'> = {
      title,
      description,
      images: images,
      location,
      city: '上海市',
      district: location.includes('区') ? location.split('区')[0] + '区' : '未知区',
      date,
      status: '待救援',
      finder: finderName
        ? { name: finderName, contact: finderContact, isPublic }
        : undefined,
      healthStatus,
      sterilizedStatus,
    };

    // 提交成功后清除草稿
    localStorage.removeItem('rescueDraft');

    onSubmit(newPost);

    // 显示成功 toast（带兔兔插画背景的样式）
    toast.success('新增救援贴审核中', {
      description: '审核通过后可在当前页面展示',
      className: 'rabbit-toast',
    });

    // 重置表单
    setTitle('');
    setDescription('');
    setLocation('');
    setDate(new Date().toISOString().split('T')[0]);
    setFinderName('');
    setFinderContact('');
    setIsPublic(false);
    setImages([]);
    setHealthStatus('未知');
    setSterilizedStatus('未知');
    setDescriptionError('');
    setFinderNameError('');
    setFinderContactError('');
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <div className="flex items-center justify-between">
            <div>
              <DialogTitle className="text-2xl text-red-800">发布救援信息</DialogTitle>
              <DialogDescription className="text-sm text-gray-600 mt-1">
                填写以下信息发布救援帖，帮助流浪兔兔找到温暖的家
              </DialogDescription>
            </div>
            {savedDraft && (
              <Button variant="ghost" size="sm" onClick={loadDraft} className="text-orange-500">
                恢复草稿
              </Button>
            )}
          </div>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* 图片上传 */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              上传图片 <span className="text-red-500">*</span>
            </label>

            {images.length > 0 && (
              <div className="grid grid-cols-3 gap-2 mb-3">
                {images.map((img, index) => (
                  <div key={index} className="relative aspect-square rounded-lg overflow-hidden border border-gray-200 bg-gray-50">
                    <img src={img} alt={`上传图片 ${index + 1}`} className="w-full h-full object-contain" />
                    <button
                      type="button"
                      onClick={() => removeImage(index)}
                      className="absolute top-1 right-1 bg-black/50 hover:bg-black/70 rounded-full p-1 transition-colors"
                    >
                      <X size={16} className="text-white" />
                    </button>
                  </div>
                ))}
              </div>
            )}

            <label className="border-2 border-dashed border-red-200 rounded-lg p-8 text-center hover:border-red-400 transition-colors cursor-pointer block">
              <input
                type="file"
                accept="image/*"
                multiple
                onChange={handleImageUpload}
                className="hidden"
                ref={fileInputRef}
              />
              <Upload size={32} className="mx-auto text-red-400 mb-2" />
              <p className="text-sm text-gray-600">
                点击上传图片（已上传 {images.length}/10）
              </p>
            </label>
          </div>

          {/* 日期选择 */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              发现日期
            </label>
            <div className="relative">
              <Calendar size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-red-400" />
              <input
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                max={new Date().toISOString().split('T')[0]}
                className="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-red-500"
              />
            </div>
          </div>

          {/* 标题 */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              标题 <span className="text-red-500">*</span>
            </label>
            <Input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="简短描述发现情况"
              maxLength={30}
            />
            <p className="text-xs text-gray-400 mt-1">{title.length}/30</p>
          </div>

          {/* 详细描述 */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              详细描述 <span className="text-red-500">*</span>
            </label>
            <Textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              onBlur={handleDescriptionBlur}
              placeholder="可根据发现时的真实状态进行描述..."
              rows={4}
              className={descriptionError ? 'border-red-500' : ''}
            />
            {descriptionError && (
              <div className="flex items-center gap-1 mt-1 text-red-500 text-sm">
                <AlertCircle size={14} />
                <span>{descriptionError}</span>
              </div>
            )}
          </div>

          {/* 发现地点 */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              发现地点 <span className="text-red-500">*</span>
            </label>
            <div className="relative">
              <MapPin size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-red-400" />
              <Input
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                placeholder="上海市虹口区"
                className="pl-10"
              />
            </div>
          </div>

          {/* 健康状态 */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              健康状态
            </label>
            <div className="flex gap-2">
              {(['健康', '仍有伤痛', '未知'] as const).map((option) => (
                <button
                  key={option}
                  type="button"
                  onClick={() => setHealthStatus(option)}
                  className={`flex-1 py-2 px-3 rounded-lg text-sm transition-colors ${
                    healthStatus === option
                      ? 'bg-green-500 text-white'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  {option}
                </button>
              ))}
            </div>
          </div>

          {/* 绝育状态 */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              绝育状态
            </label>
            <div className="flex gap-2">
              {(['已绝育', '未绝育', '未知'] as const).map((option) => (
                <button
                  key={option}
                  type="button"
                  onClick={() => setSterilizedStatus(option)}
                  className={`flex-1 py-2 px-3 rounded-lg text-sm transition-colors ${
                    sterilizedStatus === option
                      ? 'bg-blue-500 text-white'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  {option}
                </button>
              ))}
            </div>
          </div>

          {/* 发现人信息 */}
          <div className="border-t pt-4">
            <h3 className="font-medium text-gray-800 mb-3">发现人信息（可选）</h3>
            <p className="text-xs text-gray-500 mb-3">
              您可以选择是否公开发现人信息，若不公开，您的联系方式仅会由爱兔会管理员可见
            </p>

            <div className="space-y-3">
              <div>
                <Input
                  value={finderName}
                  onChange={(e) => handleFinderNameChange(e.target.value)}
                  placeholder="您的称呼"
                />
                {finderNameError && (
                  <p className="text-xs text-red-500 mt-1">{finderNameError}</p>
                )}
              </div>

              <div>
                <Input
                  value={finderContact}
                  onChange={(e) => handleFinderContactChange(e.target.value)}
                  placeholder="联系方式（手机号/微信）"
                />
                {finderContactError && (
                  <p className="text-xs text-red-500 mt-1">{finderContactError}</p>
                )}
              </div>

              <label className="flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  checked={isPublic}
                  onChange={(e) => setIsPublic(e.target.checked)}
                  className="w-4 h-4 text-red-500 rounded"
                />
                <span className="text-gray-700">公开发现人信息</span>
              </label>
            </div>
          </div>
        </div>

        <div className="flex gap-3 pt-4 border-t">
          <Button
            variant="outline"
            onClick={() => {
              saveDraft();
              toast.success('草稿已保存');
            }}
            className="flex-1"
          >
            保存草稿
          </Button>
          <Button
            onClick={handleSubmit}
            className="flex-1 bg-gradient-to-r from-red-600 to-rose-600 hover:from-pink-600 hover:to-orange-600"
          >
            发布
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
