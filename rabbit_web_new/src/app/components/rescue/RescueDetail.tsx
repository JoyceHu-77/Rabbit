import { Dialog, DialogContent, DialogTitle, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { MapPin, Calendar, User, Phone, MessageSquare, QrCode, Send, X, Upload, Edit3, Heart, Check, AlertCircle } from 'lucide-react';
import { RescuePost, RescueStatus } from './RescueTab';
import { toast } from 'sonner';
import { motion, AnimatePresence } from 'motion/react';
import { useState, useRef } from 'react';
import { Textarea } from '../ui/textarea';
import { Input } from '../ui/input';
import ImageCarousel from './ImageCarousel';
import { Label } from '../ui/label';

interface Comment {
  id: number;
  author: string;
  content: string;
  date: string;
  avatar?: string;
}

interface RescueDetailProps {
  post: RescuePost | null;
  isAdmin: boolean;
  onClose: () => void;
  onStatusUpdate: (status: RescueStatus, wechatQR?: string) => void;
  onPostUpdate: (updatedPost: RescuePost) => void;
}

// 状态流转配置
const statusFlow: Record<RescueStatus, { next: RescueStatus | null; death: RescueStatus | null }> = {
  '待救援': { next: '救援中', death: '已去世' },
  '救援中': { next: '已救援', death: '已去世' },
  '已救援': { next: '寄养中', death: '已去世' },
  '寄养中': { next: '已领养', death: '已去世' },
  '已领养': { next: null, death: null },
  '已去世': { next: null, death: null },
};

// 管理员按钮文本（根据当前状态显示不同的流转按钮文案）
const adminButtons: Record<RescueStatus, { complete: string; death: string }> = {
  '待救援': { complete: '救援完成', death: '已去世' },
  '救援中': { complete: '救援完成', death: '已去世' },
  '已救援': { complete: '寄养完成', death: '已去世' },
  '寄养中': { complete: '领养完成', death: '已去世' },
  '已领养': { complete: '', death: '' },
  '已去世': { complete: '', death: '' },
};

// 管理员完成操作需要上传二维码的状态（待救援/救援中/已救援）
const COMPLETE_REQUIRES_QR: RescueStatus[] = ['待救援', '救援中', '已救援'];

// 可配置的文案
const STATUS_FOLLOW_SUBTITLE = '您可扫描下方二维码去到微信群查看兔兔最新状态、财务公示或进行物资捐赠、捐款';

export default function RescueDetail({
  post,
  isAdmin,
  onClose,
  onStatusUpdate,
  onPostUpdate,
}: RescueDetailProps) {
  const [comments, setComments] = useState<Comment[]>([]);
  const [newComment, setNewComment] = useState('');
  const [showCommentInput, setShowCommentInput] = useState(false);

  // 救援弹窗
  const [showRescueDialog, setShowRescueDialog] = useState(false);
  const [rescueName, setRescueName] = useState('');
  const [rescueContact, setRescueContact] = useState('');

  // 管理员操作弹窗
  const [showAdminAction, setShowAdminAction] = useState(false);
  const [adminActionType, setAdminActionType] = useState<'complete' | 'death'>('complete');
  const [tempWechatQR, setTempWechatQR] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  // 编辑弹窗
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [editDescExpanded, setEditDescExpanded] = useState(false);
  const [editForm, setEditForm] = useState({
    title: '',
    description: '',
    location: '',
    healthStatus: '',
    sterilizedStatus: '',
    status: '待救援' as RescueStatus,
    wechatQR: '',
    organizerName: '',
    organizerContact: '',
  });
  const editFileInputRef = useRef<HTMLInputElement>(null);

  if (!post) return null;

  const handleRescue = () => {
    if (!rescueName.trim()) {
      toast.error('请输入联系人称呼');
      return;
    }
    if (!rescueContact.trim()) {
      toast.error('请输入联系方式');
      return;
    }
    toast.success('已提交救援申请', {
      description: '发现人和爱兔将收到通知，会尽快与您联系',
    });
    setShowRescueDialog(false);
    setRescueName('');
    setRescueContact('');
  };

  const handleAdminComplete = (type: 'complete' | 'death') => {
    setAdminActionType(type);
    // 待救援、救援中、已救援状态需要上传二维码
    if (type === 'complete' && COMPLETE_REQUIRES_QR.includes(post.status)) {
      setShowAdminAction(true);
    } else {
      // 寄养中->领养、标记已去世 等单按钮操作直接更新
      const targetStatus = type === 'complete' ? statusFlow[post.status].next : '已去世';
      if (targetStatus) {
        onStatusUpdate(targetStatus, type === 'complete' ? post.wechatQR : undefined);
        toast.success('状态已更新', {
          description: `救援贴已流转至「${targetStatus}」状态`,
        });
      }
    }
  };

  const handleQRUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setTempWechatQR(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmitAdminAction = () => {
    const targetStatus = statusFlow[post.status].next;
    if (targetStatus) {
      const qrCode = adminActionType === 'complete' ? tempWechatQR : post.wechatQR;
      onStatusUpdate(targetStatus, qrCode);
      toast.success('状态已更新', {
        description: `救援贴已流转至「${targetStatus}」状态`,
      });
      setShowAdminAction(false);
      setTempWechatQR('');
    }
  };

  const handleSubmitComment = () => {
    if (!newComment.trim()) {
      toast.error('请输入评论内容');
      return;
    }

    const comment: Comment = {
      id: comments.length + 1,
      author: '热心网友',
      content: newComment,
      date: new Date().toLocaleString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
      }),
      avatar: '👤',
    };

    setComments([...comments, comment]);
    setNewComment('');
    setShowCommentInput(false);
    toast.success('评论发布成功');
  };

  const handleOpenEdit = () => {
    setEditForm({
      title: post.title,
      description: post.description,
      location: post.location,
      healthStatus: post.healthStatus || '',
      sterilizedStatus: post.sterilizedStatus || '',
      status: post.status,
      wechatQR: post.wechatQR || '',
      organizerName: post.organizer?.name || '',
      organizerContact: post.organizer?.contact || '',
    });
    setShowEditDialog(true);
  };

  const handleSubmitEdit = () => {
    const updatedPost: RescuePost = {
      ...post,
      title: editForm.title,
      description: editForm.description,
      location: editForm.location,
      healthStatus: editForm.healthStatus,
      sterilizedStatus: editForm.sterilizedStatus,
      status: editForm.status,
      wechatQR: editForm.wechatQR,
      organizer: editForm.organizerName ? {
        name: editForm.organizerName,
        contact: editForm.organizerContact,
        isPublic: true,
      } : undefined,
    };
    onPostUpdate(updatedPost);
    toast.success('帖子已更新');
    setShowEditDialog(false);
  };

  const handleEditQRUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setEditForm({ ...editForm, wechatQR: reader.result as string });
      };
      reader.readAsDataURL(file);
    }
  };

  // 状态跟进模块 - 只要有二维码就显示（适用于所有状态）
  const showWechatQR = !!post.wechatQR;
  const currentImages = post.images?.length ? post.images : [post.images?.[0] || '/placeholder.png'];

  return (
    <Dialog open={!!post} onOpenChange={onClose}>
      <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto p-0" showClose={false}>
        <DialogTitle className="sr-only">{post.title}</DialogTitle>
        <DialogDescription className="sr-only">
          救援编号 {post.id}，发布于 {post.date}
        </DialogDescription>

        {/* 头部 */}
        <div className="sticky top-0 bg-gradient-to-br from-red-600 to-rose-600 text-white px-6 py-4 z-10">
          <button
            onClick={onClose}
            className="absolute top-4 right-4 p-1 hover:bg-white/10 rounded-full transition-colors"
            aria-label="关闭"
          >
            <X size={20} />
          </button>
          <h2 className="text-xl font-bold pr-10" aria-hidden="true">{post.title}</h2>
          <p className="text-sm text-white/80 mt-1" aria-hidden="true">编号: {post.id}</p>
        </div>

        <div className="p-6 space-y-6">
          {/* 图片轮播 */}
          <ImageCarousel
            images={currentImages}
            alt={post.title}
            badge={post.id === 'R024' ? '永远的女明星👑' : undefined}
          />

          {/* 详细描述 */}
          <div>
            <h3 className="font-semibold text-gray-800 mb-2">详细描述</h3>
            <p className="text-gray-600 leading-relaxed">{post.description}</p>
          </div>

          {/* 基本信息 - 左右两列网格布局 */}
          <div className="grid grid-cols-2 gap-3">
            <div className="flex items-center gap-2 px-3 py-2 bg-gray-50 rounded-lg">
              <MapPin size={16} className="text-red-500 flex-shrink-0" />
              <span className="text-sm text-gray-600 truncate">{post.location}</span>
            </div>

            <div className="flex items-center gap-2 px-3 py-2 bg-gray-50 rounded-lg">
              <Calendar size={16} className="text-red-500 flex-shrink-0" />
              <span className="text-sm text-gray-600">{post.date}</span>
            </div>

            {post.healthStatus && (
              <div className="flex items-center gap-2 px-3 py-2 bg-green-50 rounded-lg">
                <Heart size={16} className="text-green-600 flex-shrink-0" />
                <span className="text-sm text-green-700">{post.healthStatus}</span>
              </div>
            )}

            {post.sterilizedStatus && (
              <div className="flex items-center gap-2 px-3 py-2 bg-blue-50 rounded-lg">
                <Check size={16} className="text-blue-600 flex-shrink-0" />
                <span className="text-sm text-blue-700">{post.sterilizedStatus}</span>
              </div>
            )}

            {post.organizer && (
              <div className="flex items-center gap-2 px-3 py-2 bg-purple-50 rounded-lg">
                <User size={16} className="text-purple-600 flex-shrink-0" />
                <span className="text-sm text-purple-700">主理人</span>
                <span className="text-sm text-gray-600 truncate flex-1">
                  {post.organizer.isPublic ? post.organizer.name : '已隐藏'}
                </span>
              </div>
            )}
          </div>

          {/* 发现人信息 */}
          {post.finder && (
            <div className="bg-red-50 rounded-lg p-4">
              <h3 className="font-semibold text-gray-800 mb-3">发现人信息</h3>
              <div className="space-y-2">
                <div className="flex items-center gap-2 text-sm">
                  <User size={16} className="text-red-500" />
                  <span className="text-gray-700">
                    {post.finder.isPublic
                      ? post.finder.name
                      : post.finder.name.replace(/./g, '*')}
                  </span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <Phone size={16} className="text-red-500" />
                  <span className="text-gray-700">
                    {post.finder.isPublic
                      ? post.finder.contact
                      : post.finder.contact ? post.finder.contact.replace(/./g, '*') : ''}
                  </span>
                </div>
                {!post.finder.isPublic && (
                  <p className="text-xs text-gray-500 mt-2">
                    * 关键信息已脱敏，仅管理员可见
                  </p>
                )}
              </div>
            </div>
          )}

          {/* 状态跟进模块 - 仅已救援和寄养中显示 */}
          {showWechatQR && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-gradient-to-br from-red-50 to-rose-50 rounded-lg p-4 border-2 border-red-200"
            >
              <h3 className="font-semibold text-gray-800 mb-2 flex items-center gap-2">
                <QrCode size={18} className="text-rose-500" />
                状态跟进
              </h3>
              <p className="text-sm text-gray-600 mb-3">
                {STATUS_FOLLOW_SUBTITLE}
              </p>
              <div className="bg-white rounded-lg p-4 flex items-center justify-center">
                {post.wechatQR ? (
                  <img
                    src={post.wechatQR}
                    alt="微信群二维码"
                    className="w-32 h-32 object-contain"
                  />
                ) : (
                  <div className="w-32 h-32 bg-gray-100 rounded flex flex-col items-center justify-center text-gray-400">
                    <QrCode size={48} />
                    <span className="text-xs mt-1">暂无二维码</span>
                  </div>
                )}
              </div>
            </motion.div>
          )}

          {/* 评论区 */}
          <div className="bg-gray-50 rounded-lg p-4">
            <h3 className="font-semibold text-gray-800 mb-3 flex items-center justify-between">
              <span>评论区 ({comments.length})</span>
              {!showCommentInput && (
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => setShowCommentInput(true)}
                  className="text-red-500 hover:text-red-600 hover:bg-red-50"
                >
                  写评论
                </Button>
              )}
            </h3>

            {showCommentInput && (
              <motion.div
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                className="mb-4 space-y-2"
              >
                <Textarea
                  value={newComment}
                  onChange={(e) => setNewComment(e.target.value)}
                  placeholder="说点什么..."
                  rows={3}
                  className="resize-none"
                />
                <div className="flex gap-2 justify-end">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => {
                      setShowCommentInput(false);
                      setNewComment('');
                    }}
                  >
                    取消
                  </Button>
                  <Button
                    size="sm"
                    onClick={handleSubmitComment}
                    className="bg-gradient-to-r from-red-600 to-rose-600 hover:from-pink-600 hover:to-orange-600"
                  >
                    <Send size={14} className="mr-1" />
                    发送
                  </Button>
                </div>
              </motion.div>
            )}

            <div className="space-y-3">
              {comments.length === 0 ? (
                <p className="text-sm text-gray-500 text-center py-4">暂无评论，兔兔在这里等你哦～</p>
              ) : (
                comments.map((comment) => (
                  <motion.div
                    key={comment.id}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    className="bg-white rounded-lg p-3 border border-gray-100"
                  >
                    <div className="flex items-start gap-3">
                      <div className="w-8 h-8 rounded-full bg-gradient-to-br from-pink-400 to-orange-400 flex items-center justify-center flex-shrink-0">
                        <span className="text-sm">{comment.avatar}</span>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <span className="text-sm font-medium text-gray-800">
                            {comment.author}
                          </span>
                          <span className="text-xs text-gray-400">{comment.date}</span>
                        </div>
                        <p className="text-sm text-gray-600 leading-relaxed">
                          {comment.content}
                        </p>
                      </div>
                    </div>
                  </motion.div>
                ))
              )}
            </div>
          </div>
        </div>

        {/* 底部操作栏 */}
        <div className="sticky bottom-0 bg-white border-t p-4">
          <div className="flex gap-3">
            {/* 管理员操作按钮 */}
            {isAdmin && (
              <>
                {/* 流转和已去世按钮（仅非已领养/已去世状态显示） */}
                {post.status !== '已领养' && post.status !== '已去世' && (
                  <>
                    {adminButtons[post.status].complete && (
                      <Button
                        onClick={() => handleAdminComplete('complete')}
                        className="flex-1 bg-gradient-to-r from-rose-600 to-red-600 hover:from-orange-600 hover:to-pink-600"
                      >
                        {adminButtons[post.status].complete}
                      </Button>
                    )}
                    <Button
                      onClick={() => handleAdminComplete('death')}
                      variant="outline"
                      className="border-red-200 text-red-600 hover:bg-red-50"
                    >
                      <AlertCircle size={16} className="mr-1" />
                      {adminButtons[post.status].death}
                    </Button>
                  </>
                )}
              </>
            )}

            {/* 编辑按钮（管理员在所有状态下都可编辑，包括已领养和已去世） */}
            {isAdmin && (
              <Button
                onClick={handleOpenEdit}
                variant="outline"
                className="border-gray-200 text-gray-600 hover:bg-gray-50"
              >
                <Edit3 size={16} />
              </Button>
            )}

            {/* 用户操作按钮 */}
            {!isAdmin && post.status === '待救援' && (
              <Button
                onClick={() => setShowRescueDialog(true)}
                className="flex-1 bg-gradient-to-r from-red-600 to-rose-600 hover:from-pink-600 hover:to-orange-600"
              >
                我要救援
              </Button>
            )}

            {!isAdmin && post.status === '寄养中' && (
              <Button
                onClick={() => toast.info('领养功能请前往「领养」页面')}
                className="flex-1 bg-gradient-to-r from-red-500 to-rose-500 hover:from-purple-600 hover:to-pink-600"
              >
                我要领养
              </Button>
            )}

            {/* 评论按钮 */}
            <Button
              variant="outline"
              onClick={() => setShowCommentInput(!showCommentInput)}
              className="flex items-center gap-2"
            >
              <MessageSquare size={18} />
              评论
            </Button>
          </div>
        </div>
      </DialogContent>

      {/* 我要救援弹窗 */}
      <Dialog open={showRescueDialog} onOpenChange={setShowRescueDialog}>
        <DialogContent className="sm:max-w-md">
          <DialogTitle>提交救援申请</DialogTitle>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="rescue-name">联系人称呼</Label>
              <Input
                id="rescue-name"
                value={rescueName}
                onChange={(e) => setRescueName(e.target.value)}
                placeholder="请输入您的称呼"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="rescue-contact">联系方式</Label>
              <Input
                id="rescue-contact"
                value={rescueContact}
                onChange={(e) => setRescueContact(e.target.value)}
                placeholder="请输入您的联系方式"
              />
              <p className="text-xs text-gray-500">
                * 联系方式仅管理员可见，发现人和爱兔会将通过此方式与您联系
              </p>
            </div>
            <Button
              onClick={handleRescue}
              className="w-full bg-gradient-to-r from-red-600 to-rose-600 hover:from-pink-600 hover:to-orange-600"
            >
              提交救援
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* 管理员上传二维码弹窗 */}
      <Dialog open={showAdminAction} onOpenChange={setShowAdminAction}>
        <DialogContent className="sm:max-w-md">
          <DialogTitle>上传微信群二维码</DialogTitle>
          <p className="text-sm text-gray-500 py-2">
            请上传兔兔状态跟进微信群的二维码，上传后将在帖子详情页展示
          </p>
          <div className="space-y-4 py-4">
            <input
              type="file"
              accept="image/*"
              ref={fileInputRef}
              onChange={handleQRUpload}
              className="hidden"
            />
            <Button
              onClick={() => fileInputRef.current?.click()}
              variant="outline"
              className="w-full"
            >
              <Upload size={16} className="mr-2" />
              选择图片
            </Button>
            {tempWechatQR && (
              <div className="flex justify-center">
                <img
                  src={tempWechatQR}
                  alt="预览"
                  className="w-40 h-40 object-contain border rounded-lg"
                />
              </div>
            )}
            <Button
              onClick={handleSubmitAdminAction}
              disabled={!tempWechatQR}
              className="w-full bg-gradient-to-r from-red-600 to-rose-600 hover:from-pink-600 hover:to-orange-600"
            >
              确认上传并更新状态
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* 管理员编辑弹窗 */}
      <Dialog open={showEditDialog} onOpenChange={setShowEditDialog}>
        <DialogContent className="sm:max-w-md max-h-[85vh] overflow-hidden flex flex-col">
          <DialogTitle>编辑帖子</DialogTitle>
          <div className="space-y-4 py-4 overflow-y-auto flex-1 pr-2">
            {/* 状态选择 */}
            <div className="space-y-2">
              <Label>帖子状态</Label>
              <div className="grid grid-cols-3 gap-2">
                {(['待救援', '救援中', '已救援', '寄养中', '已领养', '已去世'] as const).map((option) => (
                  <button
                    key={option}
                    type="button"
                    onClick={() => setEditForm({ ...editForm, status: option })}
                    className={`py-2 px-3 rounded-lg text-sm transition-colors ${
                      editForm.status === option
                        ? 'bg-red-500 text-white'
                        : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                    }`}
                  >
                    {option}
                  </button>
                ))}
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-title">标题</Label>
              <Input
                id="edit-title"
                value={editForm.title}
                onChange={(e) => setEditForm({ ...editForm, title: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-location">地点</Label>
              <Input
                id="edit-location"
                value={editForm.location}
                onChange={(e) => setEditForm({ ...editForm, location: e.target.value })}
              />
            </div>
            {/* 健康状态 */}
            <div className="space-y-2">
              <Label>健康状态</Label>
              <div className="flex gap-2">
                {(['健康', '仍有伤痛', '未知'] as const).map((option) => (
                  <button
                    key={option}
                    type="button"
                    onClick={() => setEditForm({ ...editForm, healthStatus: option })}
                    className={`flex-1 py-2 px-3 rounded-lg text-sm transition-colors ${
                      editForm.healthStatus === option
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
            <div className="space-y-2">
              <Label>绝育状态</Label>
              <div className="flex gap-2">
                {(['已绝育', '未绝育', '未知'] as const).map((option) => (
                  <button
                    key={option}
                    type="button"
                    onClick={() => setEditForm({ ...editForm, sterilizedStatus: option })}
                    className={`flex-1 py-2 px-3 rounded-lg text-sm transition-colors ${
                      editForm.sterilizedStatus === option
                        ? 'bg-blue-500 text-white'
                        : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                    }`}
                  >
                    {option}
                  </button>
                ))}
              </div>
            </div>

            {/* 主理人信息 */}
            <div className="space-y-2">
              <Label htmlFor="edit-organizer-name">主理人</Label>
              <Input
                id="edit-organizer-name"
                value={editForm.organizerName}
                onChange={(e) => setEditForm({ ...editForm, organizerName: e.target.value })}
                placeholder="请输入主理人名称"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-organizer-contact">主理人联系方式</Label>
              <Input
                id="edit-organizer-contact"
                value={editForm.organizerContact}
                onChange={(e) => setEditForm({ ...editForm, organizerContact: e.target.value })}
                placeholder="请输入主理人联系方式"
              />
            </div>
            {/* 详细描述 - 可折叠 */}
            <div className="space-y-2">
              <button
                type="button"
                onClick={() => setEditDescExpanded(!editDescExpanded)}
                className="flex items-center justify-between w-full text-sm font-medium text-gray-700"
              >
                <Label htmlFor="edit-desc" className="cursor-pointer">详细描述</Label>
                <span className="text-xs text-gray-500">{editDescExpanded ? '收起' : '展开'}</span>
              </button>
              <Textarea
                id="edit-desc"
                value={editForm.description}
                onChange={(e) => setEditForm({ ...editForm, description: e.target.value })}
                rows={editDescExpanded ? 8 : 3}
                className="transition-all"
              />
            </div>
            {/* 二维码上传（管理员可选上传/修改） */}
            <div className="space-y-2">
              <Label>微信群二维码</Label>
              <input
                type="file"
                accept="image/*"
                ref={editFileInputRef}
                onChange={handleEditQRUpload}
                className="hidden"
              />
              <Button
                onClick={() => editFileInputRef.current?.click()}
                variant="outline"
                className="w-full"
              >
                <QrCode size={16} className="mr-2" />
                {editForm.wechatQR ? '修改二维码' : '上传二维码'}
              </Button>
              {editForm.wechatQR && (
                <div className="flex items-center gap-2 p-2 bg-green-50 rounded-lg">
                  <img
                    src={editForm.wechatQR}
                    alt="二维码预览"
                    className="w-16 h-16 object-contain border rounded"
                  />
                  <div className="flex-1">
                    <p className="text-xs text-green-700">已上传二维码</p>
                    <button
                      type="button"
                      onClick={() => setEditForm({ ...editForm, wechatQR: '' })}
                      className="text-xs text-red-500 hover:text-red-600"
                    >
                      删除
                    </button>
                  </div>
                </div>
              )}
            </div>
            <Button
              onClick={handleSubmitEdit}
              className="w-full bg-gradient-to-r from-red-600 to-rose-600 hover:from-pink-600 hover:to-orange-600"
            >
              保存修改
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </Dialog>
  );
}
