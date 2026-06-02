// ── Auth ──────────────────────────────────────────
export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
  phone?: string;
  roleName?: string;  // e.g. "ROLE_MEMBER", "ROLE_COACH"
}

export interface AuthResponse {
  token: string;
  type?: string;
  refreshToken?: string;
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  role: string;         // Backend returns single role string e.g. "ROLE_ADMIN"
  expiresIn?: number;   // seconds
}

export interface RefreshTokenRequest {
  refreshToken: string;
}

// ── Member ────────────────────────────────────────
export interface MemberDTO {
  id?: number;
  userId?: number;
  firstName: string;
  lastName: string;
  email: string;
  password?: string;
  phone?: string;
  address?: string;
  dateOfBirth?: string;
  gender?: string;
  emergencyContact?: string;
  emergencyPhone?: string;
  medicalNotes?: string;
  membershipStatus?: 'ACTIVE' | 'INACTIVE' | 'SUSPENDED' | 'EXPIRED';
  joinDate?: string;
  profileImageUrl?: string;
  loyaltyPoints?: number;
  assignedCoachId?: number;
  messagingEnabled?: boolean;
  enabled?: boolean;
  // Active subscription
  subscriptionId?: number;
  planName?: string;
  planId?: number;
  subscriptionStartDate?: string;
  subscriptionEndDate?: string;
  subscriptionStatus?: string;
  // Last payment
  lastPaymentStatus?: string;
  lastPaymentMethod?: string;
  lastPaymentAmount?: number;
  totalPaid?: number;
  monthlySessions?: number;
}

// ── Coach ────────────────────────────────────────
export interface CoachDTO {
  id: number;
  userId?: number;
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  specialization: string;
  bio?: string;
  certification?: string;
  hireDate?: string;
  availabilityStatus?: string;
  profileImageUrl?: string;
  ratingAvg?: number;
}

// ── Coach Rating ──────────────────────────────────
export interface CoachRatingDTO {
  id: number;
  coachId: number;
  memberId: number;
  memberName?: string;
  rating: number;
  comment?: string;
  createdAt?: string;
}

export interface RatingRequest {
  rating: number;
  comment?: string;
}

export interface CreateCoachRequest {
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  specialization: string;
  bio?: string;
  certification?: string;
  profileImageUrl?: string;
}

// ── Course ────────────────────────────────────────
export interface CourseDTO {
  id: number;
  name: string;
  description?: string;
  coachId: number;
  coachName?: string;
  dayOfWeek: string;    // Backend enum: MONDAY, TUESDAY, etc.
  startTime: string;
  endTime: string;      // Backend uses endTime, not duration
  maxParticipants: number;
  currentParticipants?: number;
  location?: string;
  active?: boolean;
}

export interface CreateCourseRequest {
  name: string;
  description?: string;
  coachId: number;
  dayOfWeek: string;
  startTime: string;
  endTime: string;
  maxParticipants: number;
  location?: string;
}

// ── Course Reservation ────────────────────────────
export interface CourseReservationDTO {
  id?: number;
  courseId: number;
  courseName?: string;
  memberId: number;
  memberName?: string;
  reservationDate: string;
  status?: string;
  createdAt?: string;
}

// ── Subscription ──────────────────────────────────
export interface SubscriptionDTO {
  id: number;
  userId: number;       // Backend uses userId, not memberId
  planId: number;
  planName?: string;
  couponId?: number;
  couponCode?: string;
  startDate: string;
  endDate: string;
  status: string;
  createdAt?: string;
}

export interface SubscriptionPlanDTO {
  id: number;
  name: string;
  description?: string;
  durationMonths: number;
  price: number;
  active?: boolean;
  createdAt?: string;
  subscribersCount?: number;
  totalRevenue?: number;
}

// ── Payment ───────────────────────────────────────
export interface PaymentDTO {
  id: number;
  subscriptionId: number;   // Backend uses subscriptionId
  amount: number;
  paymentDate: string;
  paymentMethod: string;    // Backend uses paymentMethod, not method
  status: string;
  transactionRef?: string;
}

// ── Check-In ──────────────────────────────────────
export interface CheckInDTO {
  id: number;
  memberId: number;
  memberFirstName: string;
  memberLastName: string;
  memberEmail: string;
  profileImageUrl?: string;
  checkInTime: string;
  checkOutTime?: string;
  notes?: string;
}

// ── Statistics ───────────────────────────────────
export interface StatisticsDTO {
  totalMembers: number;
  activeMembers: number;
  totalCoaches: number;
  revenueThisMonth: number;
  revenueThisYear: number;
  activeSubscriptions: number;
  expiredSubscriptions: number;
  totalCourses: number;
  totalEvents: number;
  openComplaints: number;

  // Advanced KPIs
  attendanceRate?: number;
  brokenMachinesCount?: number;
  revenueTrend?: number[];
  memberTrend?: number[];
  maleCount?: number;
  femaleCount?: number;
  expiringSoonCount?: number;
  revenuePrevMonth?: number;
  newMembersThisMonth?: number;

  // Check-in stats
  checkInsToday?: number;
  checkInsThisWeek?: number;
  checkInsThisMonth?: number;
  recentCheckIns?: CheckInDTO[];
}

// ── Complaints ───────────────────────────────────
export type ComplaintStatus = 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED';

export interface ComplaintDTO {
  id: number;
  userId: number;
  firstName: string;
  lastName: string;
  userName: string;
  subject: string;
  description: string;
  status: ComplaintStatus;
  response?: string;
  createdAt: string;
  resolvedAt?: string;
}

// ── Notifications ───────────────────────────────────
export type NotificationType = 'INFO' | 'WARNING' | 'ALERT' | 'REMINDER';

export interface NotificationDTO {
  id: number;
  title: string;
  message: string;
  type: NotificationType;
  isRead: boolean;
  createdAt: string;
  targetAll?: boolean;
  targetRole?: string;
  targetUserId?: number;
}

export interface CreateNotificationRequest {
  userId?: number;      // Specific member
  roleName?: string;    // "ROLE_MEMBER", "ROLE_COACH"
  targetAll?: boolean;
  title: string;
  message: string;
  type: NotificationType;
}

// ── API Response wrapper ──────────────────────────
export interface ApiResponse<T> {
  data: T;
  message?: string;
  success: boolean;
}

export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
}

// ── Events ────────────────────────────────────────
export interface EventDTO {
  id: number;
  title: string;
  description: string;
  eventDate: string;
  endDate: string;
  location: string;
  maxParticipants: number;
  registrationCount?: number;
  imageUrl?: string;
  active: boolean;
  createdById?: number;
  createdByName?: string;
  createdAt?: string;
}

export interface EventRegistrationDTO {
  id: number;
  eventId: number;
  eventTitle: string;
  userId: number;
  userName: string;
  firstName?: string;
  lastName?: string;
  email?: string;
  profileImageUrl?: string;
  registrationDate: string;
  status: string;
}

// ── User ──────────────────────────────────────────
export interface UserDTO {
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  address?: string;
  dateOfBirth?: string;
  gender?: string;
  profileImageUrl?: string;
  enabled: boolean;
  role: string;
  createdAt?: string;
}

// ── Salle ─────────────────────────────────────────
export interface SalleDTO {
  id?: number;
  name: string;
  capacity: number;
  currentOccupancy: number;
  status: 'DISPONIBLE' | 'OCCUPEE' | 'MAINTENANCE';
  location?: string;
  description?: string;
}

// ── Coupon ────────────────────────────────────────
export interface CouponDTO {
  id?: number;
  code: string;
  discountPercentage: number;
  validFrom?: string;
  validUntil?: string;
  maxUses?: number;
  currentUses?: number;
  active?: boolean;
}

// ── Loyalty ───────────────────────────────────────
export type LoyaltyTransactionType = 'EARN' | 'REDEEM' | 'ADMIN_ADJUST' | 'EXPIRE';
export type LoyaltyTier = 'BRONZE' | 'SILVER' | 'GOLD' | 'PLATINUM';

export interface LoyaltyTransactionDTO {
  id: number;
  memberId: number;
  type: LoyaltyTransactionType;
  points: number;
  description?: string;
  createdAt?: string;
}

export interface LoyaltyBalanceDTO {
  memberId: number;
  firstName: string;
  lastName: string;
  loyaltyPoints: number;
  tier: LoyaltyTier;
  nextTierPoints?: number;
}

export interface LoyaltyEarnRequest {
  memberId: number;
  points: number;
  description: string;
}

export interface LoyaltyRedeemRequest {
  memberId: number;
  points: number;
}

// ── Message ───────────────────────────────────────
export interface MessageDTO {
  id?: number;
  receiverId: number;
  senderId?: number;
  senderName?: string;
  receiverName?: string;
  content: string;
  sentAt?: string;
  isRead?: boolean;
}

// ── CRM ───────────────────────────────────────────
export type CrmStage = 'PROSPECT' | 'ACTIVE' | 'AT_RISK' | 'CHURNED';

export interface CrmMemberDTO {
  memberId: number;
  userId?: number;
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  membershipType?: string;
  membershipStatus?: string;
  crmStage: CrmStage;
  joinDate?: string;
  expiryDate?: string;
  daysUntilExpiry?: number;
  lastVisit?: string;
  notes?: string;
}

// ── Machine ───────────────────────────────────────
export interface MachineDTO {
  id?: number;
  name: string;
  description?: string;
  location?: string;
  status: 'AVAILABLE' | 'MAINTENANCE' | 'OUT_OF_SERVICE';
  imageUrl?: string;
  tutorialUrl?: string;
  qrCodeData?: string;
}
