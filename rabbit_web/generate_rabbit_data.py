#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import csv

csv_file = '/workspaces/default/code/src/imports/爱兔会兔兔登记.csv'

# 真实的兔子照片（来自Unsplash）
rabbit_photos = [
    'https://images.unsplash.com/photo-1622349817799-067c32295df2?w=400',
    'https://images.unsplash.com/photo-1586954152844-cd61c335b17f?w=400',
    'https://images.unsplash.com/photo-1642789310144-bf1254cc56fe?w=400',
    'https://images.unsplash.com/photo-1622349789797-c847ee0b3a2f?w=400',
    'https://images.unsplash.com/photo-1496943388386-e569e2b970a8?w=400',
    'https://images.unsplash.com/photo-1617398881039-4c977f633b0e?w=400',
    'https://images.unsplash.com/photo-1609151354448-c4a53450c6e9?w=400',
    'https://images.unsplash.com/photo-1609151257897-4d24b5a6491e?w=400',
    'https://images.unsplash.com/photo-1608704347000-f1a90cb5d65b?w=400',
    'https://images.unsplash.com/photo-1628067611203-a24e1cc77de5?w=400',
    'https://images.unsplash.com/photo-1687667326821-32409c5f2331?w=400',
    'https://images.unsplash.com/photo-1643212263626-5c5fbf20a49e?w=400',
    'https://images.unsplash.com/photo-1687667326255-42afdcaed660?w=400',
    'https://images.unsplash.com/photo-1687667326854-8475631c2652?w=400',
    'https://images.unsplash.com/photo-1643212263619-46b1a2295b94?w=400',
    'https://images.unsplash.com/photo-1496942370798-457183cb0684?w=400',
    'https://images.unsplash.com/photo-1643212263657-505473e76c7f?w=400',
    'https://images.unsplash.com/photo-1742299807163-0ea0e6055c21?w=400',
    'https://images.unsplash.com/photo-1564326140-fa771b2c0c5d?w=400',
    'https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?w=400',
]

# 特定兔兔的真实照片（用户提供）
custom_photos = {
    1: 'https://img.remit.ee/api/file/BQACAgUAAyEGAASHRsPbAAES3nJp2kROb9GzTAwObIzg8gXgWdmjPAAC-B8AAvda2VY7KJgovMxtszsE.png',  # 瓜皮
}

def map_status(current_status):
    """正确映射当前状况到应用状态
    - 已去世 -> 已去世
    - 已领养 -> 已领养
    - 待领养 -> 寄养中
    - 治疗中/治病中 -> 寄养中（用户要求）
    - 其他 -> 寄养中
    """
    if not current_status:
        return '寄养中'

    status = current_status.strip()

    # 已去世
    if '已去世' in status or '去世' in status:
        return '已去世'
    # 已领养
    elif status == '已领养':
        return '已领养'
    # 待领养、治疗中、治病中都映射为寄养中
    elif '待领养' in status or '治疗' in status or '治病' in status or '寄养' in status:
        return '寄养中'
    # 救援中保持不变
    elif '救援' in status:
        return '救援中'
    # 默认为寄养中
    else:
        return '寄养中'

def format_date(date_str):
    """格式化日期 - 保留原始格式"""
    if not date_str:
        return '未知'

    # 清理换行符但保留原始格式
    date_str = date_str.replace('\n', '').strip()

    # 直接返回原始格式，不做转换
    return date_str if date_str else '未知'

def clean_text(text):
    """清理文本，移除换行符和多余空格"""
    if not text:
        return ''
    # 合并换行符为空格
    text = ' '.join(text.split())
    # 转义单引号
    text = text.replace("'", "\\'")
    return text.strip()

def clean_name(name):
    """清理名字，将换行替换为空格"""
    if not name:
        return ''
    return ' '.join(name.split())

rabbits = []

with open(csv_file, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    rows = list(reader)

    # 遍历所有行，找出第一列是数字的数据行
    for row in rows:
        if len(row) < 12:
            continue

        seq = row[0].strip()
        if not seq or not seq.isdigit():
            continue

        i = int(seq)

        name = clean_name(row[2])
        gender = row[3].strip()
        location = row[5].strip()
        age = row[6].strip()
        sterilized = row[7].strip()
        health = row[8].strip()
        rescue_date = row[9].strip()  # 救助时间
        rescue_story = clean_text(row[10])
        current_status = row[11].strip()

        if not name:
            continue

        # 映射状态
        status = map_status(current_status)

        # 处理绝育状态
        if '绝育了' in sterilized or '绝育' in sterilized:
            sterilized_status = '绝育了'
        elif '不清楚' in sterilized:
            sterilized_status = '不清楚'
        else:
            sterilized_status = '未绝育'

        # 确保性别正确
        if gender not in ['公', '母']:
            gender = '公'

        # 组合描述：健康状况 + 绝育状态 + 救助经过
        desc_parts = []
        if health:
            desc_parts.append(f'健康状况：{health}')
        if sterilized:
            desc_parts.append(f'绝育状态：{sterilized}')
        if rescue_story:
            desc_parts.append(rescue_story)

        description = '；'.join(desc_parts) if desc_parts else f'{name}等待有缘人领养。'

        # 优先使用自定义照片，否则使用默认照片
        photo_url = custom_photos.get(i, rabbit_photos[(i-1) % len(rabbit_photos)])

        rabbit = {
            'id': i,
            'registrationDate': format_date(rescue_date),  # 使用救助时间
            'name': name,
            'gender': gender,
            'photo': photo_url,
            'location': location if location else '上海',
            'age': age if age else '未知',
            'sterilized': sterilized_status,
            'status': status,
            'description': description,
        }

        rabbits.append(rabbit)

# 按ID排序
rabbits.sort(key=lambda x: x['id'])

# 输出TypeScript代码
print("// 兔兔登记数据 - 根据爱兔会真实数据")
print("export interface RabbitData {")
print("  id: number;")
print("  registrationDate: string;")
print("  name: string;")
print("  gender: '公' | '母';")
print("  photo: string;")
print("  location: string;")
print("  age: string;")
print("  sterilized: '绝育了' | '未绝育' | '不清楚';")
print("  status: '待救援' | '救援中' | '已救援' | '寄养中' | '已领养' | '已去世';")
print("  description?: string;")
print("  finder?: {")
print("    name: string;")
print("    contact: string;")
print("    isPublic: boolean;")
print("  };")
print("  wechatQRCode?: string;")
print("}")
print()
print(f"export const rabbitDatabase: RabbitData[] = [")

for i, rabbit in enumerate(rabbits):
    comma = "," if i < len(rabbits) - 1 else ""

    print(f"  {{")
    print(f"    id: {rabbit['id']},")
    print(f"    registrationDate: '{rabbit['registrationDate']}',")
    print(f"    name: '{rabbit['name']}',")
    print(f"    gender: '{rabbit['gender']}',")
    print(f"    photo: '{rabbit['photo']}',")
    print(f"    location: '{rabbit['location']}',")
    print(f"    age: '{rabbit['age']}',")
    print(f"    sterilized: '{rabbit['sterilized']}',")
    print(f"    status: '{rabbit['status']}',")
    print(f"    description: '{rabbit['description']}',")
    print(f"  }}{comma}")

print("];")
print()
print("// 协会介绍数据")
print("export const associationInfo = {")
print("  title: '上海爱兔会',")
print("  description: `上海爱兔会是一个致力于兔兔救助、领养和保护的公益组织。我们的使命是为每一只需要帮助的兔兔提供温暖的家，传播科学养兔知识，推动动物保护理念。")
print()
print("我们提供全方位的服务：")
print("• 紧急救援：发现流浪兔，我们立即行动")
print("• 医疗协助：与专业宠物医院合作，提供优质医疗")
print("• 寄养领养：为兔兔寻找温暖的家")
print("• 科学饲养：提供专业的养护指导")
print()
print("加入我们，让每一只兔兔都能拥有幸福的生活！`,")
print("};")
print()
print("// 活动数据")
print("export interface Activity {")
print("  id: string;")
print("  type: 'checkin' | 'cloudAdopt' | 'offline';")
print("  title: string;")
print("  subtitle: string;")
print("  description: string;")
print("  status: '待参与' | '参与中' | '待上传图片' | '已完成';")
print("  banner?: string;")
print("}")
