import { useState, useRef } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { X, Upload, Image as ImageIcon, AlertCircle } from 'lucide-react';
import { toast } from 'sonner';

interface CreateRabbitPostProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (post: {
    authorName: string;
    title: string;
    content: string;
    images: string[];
  }) => void;
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

// 昵称校验（中英文、数字）
const validateNickname = (name: string): boolean => {
  const pattern = /^[\u4e00-\u9fa5a-zA-Z0-9\s]+$/;
  return pattern.test(name);
};

export default function CreateRabbitPost({ open, onClose, onSubmit }: CreateRabbitPostProps) {
  const [authorName, setAuthorName] = useState('');
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [images, setImages] = useState<string[]>([]);

  // 校验错误状态
  const [authorNameError, setAuthorNameError] = useState('');
  const [titleError, setTitleError] = useState('');
  const [contentError, setContentError] = useState('');

  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files) return;

    const fileArray = Array.from(files);
    if (images.length + fileArray.length > 9) {
      toast.error('最多只能上传9张图片');
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

  const handleAuthorNameChange = (value: string) => {
    setAuthorName(value);
    if (value && !validateNickname(value)) {
      setAuthorNameError('请输入中英文或数字昵称');
    } else {
      setAuthorNameError('');
    }
  };

  const handleTitleChange = (value: string) => {
    setTitle(value);
    if (value && !validateChineseText(value).valid) {
      setTitleError('请输入中文标题');
    } else {
      setTitleError('');
    }
  };

  const handleContentChange = (value: string) => {
    setContent(value);
    if (value && !validateChineseText(value).valid) {
      setContentError('请输入中文内容');
    } else {
      setContentError('');
    }
  };

  const handleSubmit = () => {
    // 校验必填项
    if (!authorName.trim()) {
      toast.error('请输入昵称');
      return;
    }
    if (!title.trim()) {
      toast.error('请输入标题');
      return;
    }
    if (!content.trim()) {
      toast.error('请输入内容');
      return;
    }
    if (images.length === 0) {
      toast.error('请至少上传一张图片');
      return;
    }

    // 校验昵称
    if (!validateNickname(authorName)) {
      setAuthorNameError('请输入中英文或数字昵称');
      return;
    }

    // 校验标题
    const titleResult = validateChineseText(title);
    if (!titleResult.valid) {
      setTitleError(titleResult.message);
      toast.error('请输入正确的标题');
      return;
    }

    // 校验内容
    const contentResult = validateChineseText(content);
    if (!contentResult.valid) {
      setContentError(contentResult.message);
      toast.error('请输入正确的内容');
      return;
    }

    onSubmit({
      authorName,
      title,
      content,
      images,
    });

    // 重置表单
    setAuthorName('');
    setTitle('');
    setContent('');
    setImages([]);
    setAuthorNameError('');
    setTitleError('');
    setContentError('');
  };

  const handleClose = () => {
    // 询问是否要放弃
    if (title.trim() || content.trim() || images.length > 0) {
      if (!confirm('确定要放弃编辑吗？')) {
        return;
      }
    }
    setAuthorName('');
    setTitle('');
    setContent('');
    setImages([]);
    setAuthorNameError('');
    setTitleError('');
    setContentError('');
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-red-100 to-rose-100 flex items-center justify-center">
              <span className="text-xl">🐰</span>
            </div>
            <div>
              <DialogTitle className="text-xl text-gray-800">发布兔兔动态</DialogTitle>
              <DialogDescription className="text-sm text-gray-500">
                分享你家宝贝的可爱瞬间
              </DialogDescription>
            </div>
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
                      <X size={14} className="text-white" />
                    </button>
                  </div>
                ))}
              </div>
            )}

            <label className="border-2 border-dashed border-purple-200 rounded-lg p-6 text-center hover:border-purple-400 transition-colors cursor-pointer block">
              <input
                type="file"
                accept="image/*"
                multiple
                onChange={handleImageUpload}
                className="hidden"
                ref={fileInputRef}
              />
              <ImageIcon size={28} className="mx-auto text-purple-400 mb-2" />
              <p className="text-sm text-gray-600">
                点击上传图片（已上传 {images.length}/9）
              </p>
            </label>
          </div>

          {/* 昵称 */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              昵称 <span className="text-red-500">*</span>
            </label>
            <Input
              value={authorName}
              onChange={(e) => handleAuthorNameChange(e.target.value)}
              placeholder="给你的动态取个昵称"
              maxLength={20}
            />
            <div className="flex justify-between mt-1">
              {authorNameError ? (
                <p className="text-xs text-red-500 flex items-center gap-1">
                  <AlertCircle size={12} />
                  {authorNameError}
                </p>
              ) : (
                <span />
              )}
              <p className="text-xs text-gray-400">{authorName.length}/20</p>
            </div>
          </div>

          {/* 标题 */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              标题 <span className="text-red-500">*</span>
            </label>
            <Input
              value={title}
              onChange={(e) => handleTitleChange(e.target.value)}
              placeholder="给这篇动态起个标题吧"
              maxLength={30}
            />
            <div className="flex justify-between mt-1">
              {titleError ? (
                <p className="text-xs text-red-500 flex items-center gap-1">
                  <AlertCircle size={12} />
                  {titleError}
                </p>
              ) : (
                <span />
              )}
              <p className="text-xs text-gray-400">{title.length}/30</p>
            </div>
          </div>

          {/* 内容 */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              内容 <span className="text-red-500">*</span>
            </label>
            <Textarea
              value={content}
              onChange={(e) => handleContentChange(e.target.value)}
              placeholder="说说你家兔兔的故事吧~"
              rows={5}
              className={contentError ? 'border-red-500' : ''}
            />
            <div className="flex justify-between mt-1">
              {contentError ? (
                <p className="text-xs text-red-500 flex items-center gap-1">
                  <AlertCircle size={12} />
                  {contentError}
                </p>
              ) : (
                <span />
              )}
              <p className="text-xs text-gray-400">{content.length}/500</p>
            </div>
          </div>
        </div>

        <div className="flex gap-3 pt-4 border-t">
          <Button
            variant="outline"
            onClick={handleClose}
            className="flex-1"
          >
            取消
          </Button>
          <Button
            onClick={handleSubmit}
            className="flex-1 bg-gradient-to-r from-red-500 to-rose-500 hover:from-red-600 hover:to-rose-600"
          >
            发布
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
