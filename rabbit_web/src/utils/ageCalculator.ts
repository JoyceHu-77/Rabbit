// 计算兔兔当前年龄的工具函数
export const calculateCurrentAge = (rescueDate: string, originalAge: string): string => {
  if (!rescueDate || !originalAge || rescueDate === '未知') {
    return originalAge;
  }

  // 解析救援时间（如"2025年6月"）
  const rescueDateMatch = rescueDate.match(/(\d{4})年(\d{1,2})月?/);
  if (!rescueDateMatch) {
    return originalAge;
  }

  const rescueYear = parseInt(rescueDateMatch[1]);
  const rescueMonth = parseInt(rescueDateMatch[2]);

  // 当前时间：2026年4月
  const currentYear = 2026;
  const currentMonth = 4;

  // 计算经过的月数
  const monthsPassed = (currentYear - rescueYear) * 12 + (currentMonth - rescueMonth);

  // 解析原始年龄
  let totalMonths = 0;

  // 匹配"X岁"
  const yearsMatch = originalAge.match(/(\d+)岁/);
  if (yearsMatch) {
    totalMonths += parseInt(yearsMatch[1]) * 12;
  }

  // 匹配"X个月"
  const monthsMatch = originalAge.match(/(\d+)个月/);
  if (monthsMatch) {
    totalMonths += parseInt(monthsMatch[1]);
  }

  // 加上经过的月数
  totalMonths += monthsPassed;

  // 转换回年龄格式
  const years = Math.floor(totalMonths / 12);
  const months = totalMonths % 12;

  if (years === 0) {
    return `${months}个月`;
  } else if (months === 0) {
    return `${years}岁`;
  } else {
    return `${years}岁${months}个月`;
  }
};
