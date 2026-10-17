# 社团生态平台 API 契约（v1）

前后端并行开发的唯一事实源。统一前缀 `/api/v1`，认证用 `Authorization: Bearer <token>`。
统一约定：列表接口支持 `page`(默认1)/`page_size`(默认20)；时间格式 ISO8601；金额为数字。
角色体系：平台级 `users.role` ∈ {admin, student}；社团级 `club_memberships.role_in_club` ∈ {president, officer, member}，
干事细分权限存 `membership.permissions`（JSON：`{"recruit":bool,"activity":bool,"asset":bool,"finance":bool}`）。

## 1. 认证 /auth
- POST `/auth/register` {username,password,name,email?,student_no?,major?,grade?} → User
- POST `/auth/login` (OAuth2 表单 username+password) → {access_token, token_type, user}
- GET `/auth/me` → User

## 2. 用户 /users
- GET `/users?keyword=&page=` (admin)
- PUT `/users/me` {name?,email?,major?,grade?,bio?,skill_tags?,avatar?}
- PUT `/users/{id}/role` (admin) {role} ; PUT `/users/{id}/status` (admin) {status}
- GET `/users/me/clubs` → [{club_id,name,category,logo,role_in_club,department,joined_at}]
- GET `/users/me/activities` → [Activity]
- GET `/users/me/stats` → {points, club_count, activity_count, checkin_count, work_count}
- GET `/users/me/points-records` → [PointsRecord]
- GET `/users/{id}/profile` → 用户公开信息+其社团+其成果（个人主页）

## 3. 社团 /clubs
- GET `/clubs/categories` → ["学术科技","文化艺术","体育健身","志愿公益","创新创业","兴趣爱好"]
- GET `/clubs?category=&keyword=&star=&page=` → [Club + member_count + activity_count]
- POST `/clubs/apply` (登录) {name,category,description?,charter?,advisor?,reason?} → ClubApplication
- GET `/clubs/applications?status=&mine=` → [ClubApplication]（admin 看全部；普通用户看自己）
- POST `/clubs/applications/{id}/review` (admin) {approve:bool, comment?} → 通过后自动建社团、申请人设为社长
- GET `/clubs/{id}` → ClubDetail{…, member_count, activity_count, work_count, is_joined, my_role, my_permissions}
- PUT `/clubs/{id}` (社长) {description?,logo?,advisor?,annual_intro?,max_members?}
- POST `/clubs/{id}/dissolve` (社长) {reason} → 状态置 suspended，待管理员处理
- GET `/clubs/{id}/members?keyword=&department=&role=&page=` → [Membership+user_name,major,grade,skill_tags]
- PUT `/clubs/{id}/members/{mid}/role` (社长) {role_in_club, department?}
- PUT `/clubs/{id}/members/{mid}/permissions` (社长) {permissions}
- POST `/clubs/{id}/members/{mid}/remove` (社长)
- GET `/clubs/{id}/sleepers` (社长/干事) → 90天无参与成员清单
- POST `/clubs/{id}/join`；POST `/clubs/{id}/leave`
- GET `/clubs/{id}/ratings` → [ClubRating]
- POST `/clubs/{id}/ratings/calc` (社长/admin) → 按指标重算并写入 ClubRating，同步 club.star_rating/health_score

## 4. 招新 /clubs/{id}/recruitments, /recruitments
- POST `/clubs/{id}/recruitments` (社长/有recruit权限干事) {title,description?,quota,start_time,end_time,form_fields?}
- GET `/recruitments?club_id=&status=` → [Recruitment + club_name + application_count + accepted_count]
- GET `/recruitments/{id}` → Recruitment + club 信息
- POST `/recruitments/{id}/close` (管理端)
- POST `/recruitments/{id}/apply` (登录) {intention_dept?,skill_tags?,form_data?}
- GET `/recruitments/{id}/applications?status=` (管理端) → [Application + user_name,major,grade]
- GET `/users/me/applications` → 我的投递
- POST `/applications/{id}/review` (管理端) {status:interview|accepted|rejected, interview_note?} → accepted 自动建成员关系+发通知
- GET `/recruitments/{id}/stats` → {total, pending, interview, accepted, rejected, pass_rate, by_major:[{major,count}]}

## 5. 成员异动 /clubs/{id}/change-requests
- POST `/clubs/{id}/change-requests` (本人) {type:transfer|exit|handover, payload?, reason?}
- GET `/clubs/{id}/change-requests?status=` (管理端)；GET `/users/me/change-requests`
- POST `/change-requests/{id}/review` (社长/admin) {approve:bool, comment?} → 通过后执行对应变更

## 6. 活动 /activities
- GET `/activities/types` → ["讲座","竞赛","团建","志愿","展演","培训"]
- GET `/activities?club_id=&type=&status=&approval_status=&keyword=&time_range=upcoming|past&page=`
  → [Activity + club_name + registered_count + checked_in_count + is_registered]（默认只返回 approved）
- POST `/activities` (社长/有activity权限干事) {title,type,description?,location,start_time,end_time,capacity,points_reward?,budget?,safety_plan?,joint_club_ids?} → 草稿(draft)
- PUT `/activities/{id}` (管理端，草稿或驳回时可改)
- POST `/activities/{id}/submit` (管理端) → pending，通知管理员
- POST `/activities/{id}/review` (admin) {approve:bool, comment?} → approved 时生成 checkin_code
- GET `/activities/{id}` → 详情 + partner_clubs + 统计
- POST `/activities/{id}/cancel` (管理端)
- POST `/activities/{id}/register`；POST `/activities/{id}/cancel-register`
- GET `/activities/{id}/checkin-code` (管理端) → {code, url}（前端生成二维码）
- POST `/activities/{id}/checkin` {code} → 签到成功+发积分(写 points_records)+更新通知
- GET `/activities/{id}/registrations` (管理端) → [报名名单+院系年级+签到状态]
- POST `/activities/{id}/summary` (管理端) {summary} → 归档，并自动创建满意度问卷(若无)
- POST `/activities/{id}/feedback` {rating, content?}；GET `/activities/{id}/feedbacks`
- GET `/activities/{id}/stats` (管理端) → {registered, checked_in, checkin_rate, late_rate, avg_rating, feedback_count, cost_per_person}

## 7. 场地 /venues
- GET `/venues`；POST `/venues` (admin)；PUT `/venues/{id}` (admin)
- GET `/venues/calendar?from=&to=` → [booking+venue_name+club_name]（占用日历）
- POST `/venues/{id}/bookings` (管理端) {purpose,start_time,end_time,activity_id?} → 冲突检测(同场地已批准时段重叠即拒)
- GET `/bookings?mine=&club_id=&status=` → 我的/本社团/全部(admin)
- POST `/bookings/{id}/review` (admin) {approve:bool,comment?}；POST `/bookings/{id}/cancel`
- GET `/venues/usage-stats` → [{venue_id,name,booking_count,total_hours,utilization}]

## 8. 物资 /clubs/{id}/assets
- GET `/clubs/{id}/assets` (本社团管理端)；POST `/clubs/{id}/assets` {name,category?,total,note?}
- PUT `/assets/{id}`；DELETE `/assets/{id}`
- POST `/assets/{id}/borrow` {quantity,note?}；POST `/assets/{id}/return` {quantity}
- GET `/assets/{id}/records` → 流水
- GET `/clubs/{id}/assets/stats` → {total_kinds,total_items,borrowed,idle_list:[闲置>60天]}

## 9. 财务 /clubs/{id}/finances
- GET `/clubs/{id}/finances?type=&status=&page=` (管理端)
- POST `/clubs/{id}/finances` (管理端) {type,category,amount,title,note?,activity_id?} → expense 默认 pending 待审批，income 直接 approved
- GET `/finances?status=&type=&club_id=&page=&page_size=` (admin) → 全部经费流水分页列表，每条带 club_name 和 created_by_name（审批中心-经费报销 Tab）
- GET `/finances/pending-count` (admin) → {count} 待审批经费数
- POST `/finances/{id}/review` (admin) {approve:bool,comment?}
- GET `/clubs/{id}/finance/stats` → {balance, total_income, total_expense, by_category:[{category,amount}], monthly:[{month,income,expense}], top_cost_activities:[{title,cost,per_person}], budget_alert:bool}

## 10. 内容互动
### 公告 /announcements
- GET `/announcements?club_id=&limit=`；POST `/announcements` (admin 或社团管理端带 club_id)；POST `/announcements/{id}/top` (admin)；DELETE `/announcements/{id}`
### 作品成果 /works
- GET `/works?club_id=&type=&keyword=&page=` → [Work+club_name+user_name+like_count]
- POST `/works` (登录) {club_id,title,type,description?,url?,award_level?}
- POST `/works/{id}/like` (切换点赞)；DELETE `/works/{id}` (本人或管理端)
### 讨论区 /posts
- GET `/posts?club_id=&keyword=&page=` → [Post+user_name+comment_count+like_count]
- POST `/posts` {club_id?,title,content}；GET `/posts/{id}` (views+1)
- POST `/posts/{id}/comments` {content}；GET `/posts/{id}/comments`
- POST `/posts/{id}/like`；DELETE `/posts/{id}` (本人/admin)
### 问卷 /surveys
- GET `/surveys?club_id=&activity_id=`；POST `/surveys` (管理端) {activity_id?,club_id?,title,questions}
- GET `/surveys/{id}` → 问卷+是否已答
- POST `/surveys/{id}/respond` {rating, answers?}
- GET `/surveys/{id}/results` (管理端) → {count, avg_rating, rating_dist:[1..5], answers:[…]}
### 通知 /notifications
- GET `/notifications?unread=&page=`；GET `/notifications/unread-count`
- POST `/notifications/{id}/read`；POST `/notifications/read-all`
### 文件 /files
- POST `/files/upload` (multipart: file, club_id?, category?) → FileRecord（存 backend/uploads，URL 前缀 /static）
- GET `/files?club_id=&category=&keyword=`；GET `/files/{id}/download`；DELETE `/files/{id}` (本人/admin)

## 11. 数据分析（核心）/dashboard, /analytics
- GET `/dashboard/overview` (admin 校级) → {total_users,total_clubs,total_members,total_activities,total_registrations,checkin_rate,avg_rating,active_users_30d,new_members_30d,star_dist:[{star,count}],category_dist:[…]}
- GET `/dashboard/club/{id}` (本社团管理端) → {member_count,member_growth:[{month,count}],retention_rate,sleeper_count,activity_count,activity_stats:[{title,registered,checkin_rate,avg_rating}],avg_attendance,avg_rating,health_score,star_rating,weaknesses:[…]}
- GET `/dashboard/me` → 个人面板 {points,points_rank,club_count,activity_count,checkin_count,total_hours,skill_tags,monthly_activity:[{month,count}]}
- GET `/dashboard/club-ranking?limit=` → 活跃度排行榜（score=成员*1+活动*5+报名*0.5+满意度*10）
- GET `/dashboard/activity-trend?weeks=12` → [{week,activities,registrations}]
- GET `/dashboard/top-users?limit=`；GET `/dashboard/hot-activities?limit=`
- GET `/analytics/warnings` (admin) → [{club_id,name,level:red|yellow,reasons:[…],health_score}]（长期无活动/成员流失>30%/经费异常/满意度<3）
- GET `/analytics/club/{id}/churn-risk` (管理端) → [{user_id,name,last_active,days_inactive,drop_rate,level}]
- GET `/analytics/recommend/clubs` (登录) → 按 skill_tags 与社团类别/标签匹配+热度排序，附 reason
- GET `/analytics/recommend/activities` (登录) → 基于已加入社团类别+热门度的活动推荐，附 reason
- GET `/analytics/recommend/talents?skill=&club_id=` (管理端) → 跨社团技能匹配人才[{user_id,name,major,skill_tags,active_score}]
- GET `/analytics/compare?category=` → 同类社团横向对比[{club_id,name,members,activities,attendance,rating,score}]
- GET `/analytics/reports/{kind}.csv?from=&to=` (admin/管理端) kind ∈ members|activities|finance|recruit|annual → CSV 下载(utf-8-sig)

## 12. 联合项目 /projects（增值功能①）
- GET `/projects?status=&club_id=` → [Project+lead_club_name+club_count+task_done/task_total]
- POST `/projects` (社长) {title,description?,start_date?,end_date?,partner_club_ids?}
- GET `/projects/{id}` → 详情+参与社团+任务树
- PUT `/projects/{id}` (牵头社团管理端)；POST `/projects/{id}/clubs` {club_id}；DELETE `/projects/{id}/clubs/{club_id}`
- POST `/projects/{id}/tasks` {title,description?,assignee_id?,club_id?,due_date?}
- PUT `/tasks/{id}` {status?,assignee_id?,title?,description?,due_date?}；DELETE `/tasks/{id}`
- GET `/projects/{id}/progress` → {total,done,doing,todo,progress_pct,by_club:[{club_id,name,total,done}]}

## 13. AI 辅助 /ai（增值功能②，规则+数据驱动，无外部依赖）
- POST `/ai/activity-plan` (管理端) {type,theme,scale} → {outline:[环节…],budget_suggestion,checklist:[…],duration_suggestion}（预算建议取历史同类活动人均成本）
- POST `/ai/activity-summary` (管理端) {activity_id} → {summary}（按报名/签到/满意度/经费数据自动成文，可一键写入活动归档）
- GET `/ai/activity-diagnosis/{activity_id}` (管理端) → {metrics:{…},vs_avg:{…},strengths:[…],weaknesses:[…],suggestions:[…]}（与同类型历史均值对比）
- GET `/ai/history?gen_type=plan|summary|diagnose&limit=20` (登录；管理员看全部，其余看本人及所管社团) → [{id,user_id,user_name,club_id,club_name,gen_type,input_summary,result_text,created_at}]（三个生成端点成功后自动落库 ai_generations 表，供历史回看）

## 14. 系统
- GET `/`；GET `/health`
- GET `/logs?user_id=&action=&page=` (admin 操作日志)
- GET `/search?q=&type=club|activity|work|post|user&page=` → 分组结果 {clubs:[],activities:[],works:[],posts:[],users:[]}

## 关键业务规则
1. 签到发积分：checkin 成功 → user.points += activity.points_reward，写 points_records，给本人发通知。
2. 录用即入社：招新 application 通过 → 自动创建 membership(member) + 通知。
3. 活动归档自动发问卷：写 summary 时若无关联 survey 则自动创建默认满意度问卷并给签到用户发通知。
4. 活跃度(成员)：近90天 报名*2+签到*3+发帖*2+评论*1+作品*3，分数用于沉睡成员与流失预测。
5. 社团健康分：成员留存30% + 活动频率20% + 出勤率20% + 满意度20% + 经费健康10%（0-100；≥85五星，70四星，55三星，40二星，以下一星）。
6. 所有审批/重要写操作写 operation_logs。
7. 敏感信息：非本人/非管理端返回用户时隐藏 email、student_no。
