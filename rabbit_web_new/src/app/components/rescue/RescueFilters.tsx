import { useState } from 'react';
import { X, Calendar as CalendarIcon, Info } from 'lucide-react';
import { Button } from '../ui/button';
import { motion } from 'motion/react';
import { Calendar } from '../ui/calendar';
import type { RescueStatus } from './RescueTab';

export interface FilterState {
  statuses: RescueStatus[];
  districts: string[];
  dateRange?: { from?: Date; to?: Date };
  myPosts: boolean;
}

interface RescueFiltersProps {
  onFilter: (filters: FilterState) => void;
  onClose: () => void;
  availableDates?: Date[]; // 可用的日期列表，用于禁用无数据的日期
}

export default function RescueFilters({ onFilter, onClose, availableDates }: RescueFiltersProps) {
  const [selectedStatuses, setSelectedStatuses] = useState<RescueStatus[]>([]);
  const [selectedDistricts, setSelectedDistricts] = useState<string[]>([]);
  const [dateRange, setDateRange] = useState<{ from?: Date; to?: Date }>({});
  const [myPosts, setMyPosts] = useState(false);
  const [showDatePicker, setShowDatePicker] = useState(false);

  const statuses: RescueStatus[] = ['待救援', '救援中', '已救援', '寄养中', '已领养', '已去世'];
  const districts = ['黄浦区', '徐汇区', '长宁区', '静安区', '普陀区', '虹口区', '杨浦区', '浦东新区'];

  const toggleStatus = (status: RescueStatus) => {
    setSelectedStatuses(prev =>
      prev.includes(status)
        ? prev.filter(s => s !== status)
        : [...prev, status]
    );
  };

  const toggleDistrict = (district: string) => {
    setSelectedDistricts(prev =>
      prev.includes(district)
        ? prev.filter(d => d !== district)
        : [...prev, district]
    );
  };

  const handleReset = () => {
    setSelectedStatuses([]);
    setSelectedDistricts([]);
    setDateRange({});
    setMyPosts(false);
    onFilter({ statuses: [], districts: [], myPosts: false });
    onClose();
  };

  const handleApply = () => {
    onFilter({
      statuses: selectedStatuses,
      districts: selectedDistricts,
      dateRange,
      myPosts,
    });
    onClose();
  };

  const getStatusTooltip = (status: RescueStatus) => {
    const tooltips = {
      '待救援': '发布帖子后未救援的',
      '救援中': '已有用户选择救援',
      '已救援': '完成救援，在医院中/或者寄养中',
      '寄养中': '已送至寄养家庭/机构，等待爱心人士领养中',
      '已领养': '已有用户领养',
      '已去世': '兔兔已回到兔星',
    };
    return tooltips[status];
  };

  return (
    <motion.div
      initial={{ height: 0, opacity: 0 }}
      animate={{ height: 'auto', opacity: 1 }}
      exit={{ height: 0, opacity: 0 }}
      className="bg-white border-b border-red-100 overflow-hidden shadow-sm"
    >
      <div className="p-4 max-w-2xl mx-auto">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold text-gray-800">筛选条件</h3>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <X size={20} className="text-gray-500" />
          </button>
        </div>

        <div className="space-y-4">
          {/* 日期筛选 */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">日期范围</label>
            <div className="relative">
              <Button
                variant="outline"
                className="w-full justify-start text-left font-normal"
                onClick={() => setShowDatePicker(!showDatePicker)}
              >
                <CalendarIcon className="mr-2 h-4 w-4" />
                {dateRange.from ? (
                  dateRange.to ? (
                    <>
                      {dateRange.from.toLocaleDateString()} - {dateRange.to.toLocaleDateString()}
                    </>
                  ) : (
                    dateRange.from.toLocaleDateString()
                  )
                ) : (
                  <span>选择日期范围</span>
                )}
              </Button>
              {showDatePicker && (
                <div className="absolute top-full left-0 mt-1 z-50 bg-white rounded-lg shadow-lg border">
                  <Calendar
                    mode="range"
                    selected={{ from: dateRange.from, to: dateRange.to }}
                    onSelect={(range) => {
                      setDateRange({ from: range?.from, to: range?.to });
                      // 关闭日期选择器但不关闭筛选面板
                      setShowDatePicker(false);
                    }}
                    numberOfMonths={1}
                  />
                  <div className="p-3 border-t flex gap-2">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => {
                        setDateRange({});
                        setShowDatePicker(false);
                      }}
                    >
                      清除日期
                    </Button>
                    <Button
                      size="sm"
                      onClick={() => setShowDatePicker(false)}
                      className="bg-red-500 hover:bg-red-600"
                    >
                      确定
                    </Button>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* 地点筛选 */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              地点（上海市行政区）
            </label>
            <div className="flex flex-wrap gap-2">
              {districts.map((district) => (
                <button
                  key={district}
                  onClick={() => toggleDistrict(district)}
                  className={`px-3 py-1.5 text-sm rounded-full border transition-colors ${
                    selectedDistricts.includes(district)
                      ? 'bg-red-500 text-white border-red-500'
                      : 'border-red-200 hover:bg-red-50'
                  }`}
                >
                  {district}
                </button>
              ))}
            </div>
          </div>

          {/* 我的发布 */}
          <div>
            <button
              onClick={() => setMyPosts(!myPosts)}
              className={`w-full px-4 py-3 text-sm rounded-xl border transition-colors flex items-center justify-between ${
                myPosts
                  ? 'bg-red-500 text-white border-red-500'
                  : 'border-red-200 hover:bg-red-50'
              }`}
            >
              <span className="font-medium">仅看我的发布</span>
              {myPosts && <span>✓</span>}
            </button>
          </div>

          {/* 状态筛选 */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">状态</label>
            <div className="flex flex-wrap gap-2">
              {statuses.map((status) => (
                <div key={status} className="relative group">
                  <button
                    onClick={() => toggleStatus(status)}
                    className={`px-3 py-1.5 text-sm rounded-full border transition-colors ${
                      selectedStatuses.includes(status)
                        ? 'bg-red-500 text-white border-red-500'
                        : 'border-red-200 hover:bg-red-50'
                    }`}
                  >
                    {status}
                    <Info size={12} className="inline-block ml-1 opacity-60" />
                  </button>
                  {/* 工具提示 */}
                  <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 bg-gray-800 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none z-10">
                    {getStatusTooltip(status)}
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="flex gap-2 pt-2">
            <Button variant="outline" size="sm" onClick={handleReset} className="flex-1">
              重置
            </Button>
            <Button
              size="sm"
              onClick={handleApply}
              className="flex-1 bg-gradient-to-r from-red-600 to-rose-600 hover:from-pink-600 hover:to-orange-600"
            >
              应用筛选
            </Button>
          </div>
        </div>
      </div>
    </motion.div>
  );
}
