# توثيق فني شامل: نظام المباريات (Matches System)

> الهدف من هذا المستند: توفير تحليل كامل ودقيق لنظام "المباريات" كما هو مطبَّق حاليًا في تطبيق أكاديمية نوجوم (Backend: Node/Express/Mongoose + Frontend: Flutter/Riverpod)، بحيث يمكن نسخ نفس النظام وتطبيقه بنفس المنطق والسلوك في تطبيق آخر.

## ملخص عام

نظام المباريات هو أداة **جدولة وتذكير (Fixture Scheduler + Reminder Log)** وليس نظام نتائج مباريات كامل. أي:

- لا يوجد فيه نتيجة (score) أو نتيجة فوز/خسارة/تعادل.
- لا يوجد فريق خصم كـ Entity منفصل.
- لا توجد حالة (status) للمباراة (مجدولة/جارية/منتهية/ملغاة).
- هو أساسًا: إنشاء مباراة (اسم، مكان، تاريخ، وقت، ملاحظات)، إضافة لاعبين لها من قائمة لاعبي الأكاديمية، وإرسال/تسجيل تذكيرات واتساب لأولياء الأمور.
- غير مرتبط بنظام التقييم (Evaluation) ولا بالمجموعات (Groups) — اللاعبون يُضافون فرديًا وليس بالمجموعة.

---

## 1. طبقة الـ Backend (Node.js / Express / Mongoose)

### 1.1 نموذج البيانات — `Match` Model

**Collection:** `Match`

| الحقل | النوع | القيود |
|---|---|---|
| `academyId` | ObjectId (ref `Academy`) | required — كل مباراة تتبع أكاديمية واحدة |
| `sport` | String | اختياري، افتراضي null — لدعم الأكاديميات متعددة الرياضات |
| `name` | String | required، طول 2–150 حرف |
| `location` | String | required، حتى 200 حرف |
| `date` | String | required، regex `^\d{4}-\d{2}-\d{2}$` (تُخزَّن كنص وليس Date حقيقي) |
| `time` | String | required، regex `^\d{2}:\d{2}$` (نص أيضًا) |
| `notes` | String | اختياري، حتى 500 حرف |
| `playerIds` | Array\<ObjectId ref `Player`\> | افتراضي `[]` |
| `reminderLog` | Array من `{ playerId: ref Player, sentAt: Date }` | افتراضي `[]` — سجل تذكيرات مضمّن (embedded) |
| `createdAt` / `updatedAt` | Timestamps | تلقائي |

**Indexes:**
- `{ academyId: 1 }`
- `{ academyId: 1, date: 1 }` (لتسريع فرز/فلترة المباريات حسب التاريخ لكل أكاديمية)

**ملاحظة تصميمية مهمة:** `date` و `time` مخزَّنان كنصوص (string) بصيغة ثابتة بدلاً من نوع `Date` حقيقي، لتفادي مشاكل المنطقة الزمنية عند العرض، مع فرز يعتمد على الترتيب المعجمي للنص (يعمل صحيحًا لأن الصيغة ISO-like `YYYY-MM-DD` و `HH:mm`).

### 1.2 Endpoints (Controller)

جميعها تحت `protect` middleware (تتطلب توثيق/تسجيل دخول).

| Endpoint | Method | الوصف | الصلاحية |
|---|---|---|---|
| `/matches` | GET | قائمة مباريات مقسّمة صفحات (pagination)، مفلترة حسب `academyId` (تلقائيًا حسب دور المستخدم) وفلتر اختياري `sport`، مرتبة `date desc, time desc` | أي مستخدم موثّق (القراءة مفتوحة للجميع) |
| `/matches/:id` | GET | تفاصيل مباراة + جلب بيانات اللاعبين الكاملة (`players`) من `playerIds` | أي مستخدم موثّق |
| `/matches` | POST | إنشاء مباراة جديدة. لو المستخدم `super_admin` يمكنه تمرير `academyId`، غير ذلك تُستخدم أكاديمية المستخدم الحالي تلقائيًا. يسجّل نشاط `CREATE_MATCH` | `super_admin`, `supervisor` فقط |
| `/matches/:id` | PUT | تحديث حقول محددة فقط (whitelist): `name, location, date, time, notes, sport`. يتحقق أن المباراة تتبع أكاديمية المستخدم (إلا super_admin). يسجّل `UPDATE_MATCH` | `super_admin`, `supervisor` فقط |
| `/matches/:id` | DELETE | حذف مع نفس فحص الملكية. يسجّل `DELETE_MATCH` | `super_admin`, `supervisor` فقط |
| `/matches/:id/players` | POST | إضافة لاعبين — تدمج `playerIds` الجديدة مع الموجودة عبر `Set` لمنع التكرار، بدون حد أقصى للعدد | `super_admin`, `supervisor` فقط |
| `/matches/:id/players/:playerId` | DELETE | إزالة لاعب واحد من `playerIds` | `super_admin`, `supervisor` فقط |
| `/matches/:id/reminders/:playerId` | POST | تسجيل تذكير: يضيف `{playerId, sentAt: now}` إلى `reminderLog`. **لا يرسل رسالة فعليًا** — الإرسال الفعلي يحدث من جهة العميل (Flutter) عبر فتح واتساب، وهذا الـ endpoint فقط "يوثّق" أنه تم فتح واتساب | `super_admin`, `supervisor` فقط |

**نمط التحقق من الملكية (مكرر في كل عملية تعديل):**
```
if (user.role !== 'super_admin' && match.academyId.toString() !== user.academyId.toString()) {
  → 403/404
}
```

**Validation:** عبر `express-validator` على كل من name/location/date/time/notes/sport بنفس قيود الـ Schema (طول، regex).

**Activity Logging:** تُسجَّل فقط عمليات `CREATE_MATCH` / `UPDATE_MATCH` / `DELETE_MATCH` في سجل النشاط العام؛ عمليات إضافة/إزالة لاعب والتذكيرات **لا تُسجَّل** في activity log منفصل.

---

## 2. طبقة الـ Frontend (Flutter — Clean Architecture + Riverpod)

البنية تتبع نفس نمط باقي الميزات في التطبيق (Domain / Data / Presentation)، مسجّلة عبر `get_it` (DI).

### 2.1 Domain Layer

**`MatchEntity`:**
```
id, academyId, sport?, name, location, date, time, notes?,
playerIds, reminderCount, lastReminderAt?, createdAt, updatedAt?
+ computed: playersCount (= playerIds.length)
```

**`MatchPlayerEntity`** (إسقاط مبسّط للاعب داخل سياق المباراة، وليس Entity اللاعب الكامل):
```
id, fullName, playerCode, imageUrl?, parentPhone, parentName
```

**Repository Contract** (`MatchesRepository`):
```
getMatches, getMatchById, createMatch, addPlayersToMatch,
removePlayerFromMatch, logReminder, deleteMatch
```
كل دالة تُرجع `Either<Failure, T>` (باستخدام مكتبة `dartz`).

**Usecases:** كلاس منفصل لكل عملية (نمط usecase-per-action القياسي في المشروع):
`GetMatchesUsecase, GetMatchUsecase, CreateMatchUsecase, AddPlayersToMatchUsecase, RemovePlayerFromMatchUsecase, LogReminderUsecase, DeleteMatchUsecase`

### 2.2 Data Layer

- **`MatchModel` / `MatchMapper.fromJson`:** يحسب من جانب العميل:
  - `reminderCount` = `reminderLog.length`
  - `lastReminderAt` = أقصى (max) قيمة `sentAt` في `reminderLog`
  
  (هذان الحقلان **غير مخزَّنين** كحقول منفصلة في الـ backend، بل محسوبان عند التحويل من JSON).

- **`MatchesRemoteDataSource`:** HTTP wrapper فوق `ApiClient` يستدعي نفس الـ endpoints أعلاه.

- **`MatchesRepositoryImpl`:** نمط try/catch قياسي يحوّل الأخطاء إلى `Failure` عبر `Either`.

### 2.3 State Management (Riverpod)

```dart
matchesListProvider = FutureProvider.autoDispose.family<List<MatchEntity>, String academyId>
matchDetailProvider = FutureProvider.autoDispose.family<({MatchEntity match, List<MatchPlayerEntity> players}), String matchId>

class MatchesNotifier extends StateNotifier<AsyncValue<void>> {
  // create / addPlayers / removePlayer / logReminder / delete
  // كل دالة تستدعي الـ Usecase المسجّل عبر sl<UseCase>()
}
```

### 2.4 الشاشات وتدفقات المستخدم (User Flows)

#### 1) `MatchesListScreen(academyId)`
- قائمة كروت (`_MatchCard`): الاسم، المكان • التاريخ والوقت.
- حالة فارغة (empty state) بأيقونة ونص.
- Pull-to-refresh يعيد تحميل `matchesListProvider` (invalidate).
- زر FAB "مباراة جديدة" يظهر فقط لو `canManageOperations == true`.
- الضغط على كارت → `MatchDetailScreen`.

#### 2) `CreateMatchScreen(academyId)`
نموذج (form) يحتوي:
- Dropdown الرياضة (`sport`) — يظهر فقط إن كانت الأكاديمية `isMultiSport`، وإجباري في هذه الحالة.
- اسم المباراة (حد أدنى حرفين).
- المكان (إجباري).
- التاريخ عبر `showDatePicker` — الحد الأدنى = أمس، الحد الأقصى = بعد سنتين.
- الوقت عبر `showTimePicker`.
- ملاحظات (اختياري، حقل 3 أسطر).
- عند الإرسال: يُبنى `date` بصيغة `yyyy-MM-dd` و`time` بصيغة `HH:mm` كنصوص → استدعاء `createMatch` → الانتقال (`pushReplacement`) إلى `MatchDetailScreen`.

#### 3) `MatchDetailScreen(matchId, academyId)`
- كارت معلومات (`_MatchInfoCard`): أيقونة، الاسم، الرياضة، المكان، التاريخ، الوقت، عدد اللاعبين، الملاحظات.
- زر "إضافة لاعبين للمباراة" (لأصحاب الصلاحية فقط) → يفتح `SelectMatchPlayersScreen`، وعند العودة بنتيجة `true` يعاد تحميل تفاصيل المباراة.
- قائمة اللاعبين، كل لاعب معه زر أيقونة "تذكير بالمباراة" (لأصحاب الصلاحية فقط)، وزر جماعي "إرسال للجميع".

**منطق التذكير (الأهم في الميزة):**
- رسالة واتساب ثابتة بالعربية (template) تتضمن: اسم اللاعب، اسم المباراة، المكان، التاريخ، الوقت.
- عند الضغط على تذكير للاعب: يُفتح واتساب عبر `WhatsAppUtils.open(phone, message)`.
- **الشرط الحاسم:** لا يُسجَّل التذكير في السيرفر (`logReminder`) إلا إذا نجح فتح واتساب فعليًا (`opened == true`). أي أن التسجيل يعتمد على "نية الإرسال" (فتح التطبيق) وليس تأكيد استلام أو قراءة الرسالة.
- "إرسال للجميع": يستدعي نفس المنطق لكل لاعب **بالتتابع (sequentially)**، بدون تنفيذ متوازٍ (parallel) وبدون معالجة فشل جزئي أو تراجع (rollback) لو فشل أحدهم.

#### 4) `SelectMatchPlayersScreen(matchId, academyId, alreadyAdded)`
- بحث مع debounce 400ms عن لاعبي الأكاديمية (`playersProvider`).
- عند اختيار لاعب: تحديث محلي متفائل (optimistic update) يعلّمه كـ"مُضاف" فورًا، مع استدعاء `addPlayers` بلاعب واحد فقط في كل مرة، والتراجع محليًا لو فشل الطلب.
- اللاعبون المُضافون مسبقًا يظهرون بشارة خضراء "تمت الإضافة ✓".
- زر "إنشاء القائمة" يغلق الشاشة فقط (`pop(true)`) — لا يوجد إرسال دفعي (batch)؛ الإضافات تحدث واحدة تلو الأخرى فور الاختيار.

### 2.5 تكامل واتساب — `WhatsAppUtils`

ترتيب المحاولات عند فتح واتساب:
1. `whatsapp://send` (رابط مباشر).
2. `https://wa.me/` عبر التطبيق الخارجي.
3. `https://wa.me/` كـ fallback للمتصفح الافتراضي.

**تطبيع رقم الهاتف:** إزالة كل شيء عدا الأرقام و`+`؛ الأرقام المصرية المحلية بصيغة `0XXXXXXXXXX` (11 رقم) تُحوَّل إلى `2XXXXXXXXXX` (إضافة كود الدولة 20). **هذا منطق مخصص لمصر ويحتاج تعميم لو التطبيق الجديد يستهدف دول أخرى.**

### 2.6 التوجيه (Routing)

- المسار: `matchesList = '/academies/:id/matches'`.
- **لا يوجد مسار مخصص (go_router route)** لتفاصيل المباراة أو إنشائها — تُفتح عبر `Navigator.push(MaterialPageRoute(...))` وليس عبر مسارات معلنة، لذلك لا يوجد دعم Deep Linking لمباراة محددة.
- شريط التنقل الجانبي/السفلي يفعّل تبويب "المباريات" لو المسار الحالي يحتوي `/matches`.

---

## 3. الصلاحيات (RBAC)

| الدور | صلاحية المباريات |
|---|---|
| `super_admin` | كامل: عرض + إنشاء + تعديل + حذف + إدارة لاعبين + تذكيرات |
| `supervisor` | نفس صلاحيات super_admin (باستثناء تحديد academyId عند الإنشاء) |
| `academy_admin` | **عرض فقط** — الواجهة تخفي زر الإضافة/التعديل/التذكير، وتضيف نصًا "المباريات (عرض فقط)" |
| `coach` | **ممنوع بالكامل** — لا يظهر التبويب أصلاً في لوحة التحكم الخاصة به |

**مهم:** القيد مطبَّق في مكانين مستقلين — الواجهة (تخفي الأزرار) **و** السيرفر (`restrictTo('super_admin','supervisor')` في الراوت)، بحيث لا يمكن تجاوزه حتى لو تم استدعاء الـ API مباشرة.

`canManageOperations` = `isSuperAdmin || isSupervisor` (خاصية محسوبة في `UserEntity`).

---

## 4. نقاط الدخول للميزة

- شبكة الإجراءات السريعة في لوحة التحكم (Dashboard) — أيقونة `sports_soccer`، والتسمية تتغير حسب الصلاحية ("المباريات" أو "المباريات (عرض فقط)").

---

## 5. الأشياء غير الموجودة عمدًا (لتوضيح حدود النظام)

- لا نتيجة/سكور، لا حالة فوز/خسارة/تعادل.
- لا فريق خصم كـ Entity، ولا حالة (status) دورة حياة (مجدولة/جارية/منتهية/ملغاة).
- لا ربط بنظام التقييم (Evaluation).
- لا ربط بالمجموعات (Groups) — الإضافة فردية للاعبين وليس بالمجموعة.
- لا سجل نشاط منفصل لعمليات إضافة/إزالة لاعب أو التذكيرات (فقط CREATE/UPDATE/DELETE للمباراة نفسها).

---

## 6. خطوات مقترحة لإعادة البناء في تطبيق آخر

1. **Backend:**
   - إنشاء موديل `Match` بنفس الحقول والـ indexes أعلاه.
   - بناء نفس الـ 8 endpoints بنفس قواعد الصلاحية (roles) وquery الفلترة حسب `academyId`.
   - تطبيق نفس منطق whitelist عند التحديث لمنع تعديل حقول غير مسموحة (مثل `academyId`, `playerIds`, `reminderLog` مباشرة).
   - استخدام نفس نمط تخزين `date`/`time` كنصوص لو أردت تفادي مشاكل timezone، أو التبديل لـ `Date` حقيقي إن كان التطبيق الجديد يحتاج فرز/مقارنة زمنية أدق.

2. **Frontend:**
   - تكرار بنية Clean Architecture (Entity → Repository → Usecases → Provider → Screens) بنفس التسلسل.
   - تنفيذ نفس الشاشات الأربعة بنفس تدفق التنقل (list → detail ↔ create/select-players).
   - **قرار تصميمي يستحق المراجعة عند إعادة البناء:** حاليًا "تسجيل التذكير" يعتمد فقط على نجاح فتح تطبيق واتساب، وليس على تأكيد فعلي بالإرسال. إذا كانت الدقة مهمة في التطبيق الجديد، يمكن التفكير في تحسين هذا (مثلاً عبر webhook تأكيد من WhatsApp Business API بدلاً من `wa.me` scheme).
   - تعميم دالة تطبيع رقم الهاتف بدلاً من تثبيتها على كود مصر (20)، إذا كان التطبيق الجديد متعدد الدول.
   - إن أردت دعم Deep Linking لمباراة معيّنة، أضف route فعلي في `go_router` بدل الاعتماد فقط على `Navigator.push`.

3. **الصلاحيات:** طبّق نفس مصفوفة الأدوار (super_admin/supervisor = كامل، academy_admin = قراءة فقط، coach = ممنوع) في كلٍّ من الواجهة والسيرفر بشكل مستقل، لضمان عدم كفاية حجب الواجهة فقط.
