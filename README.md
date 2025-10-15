# 🎬 LandTube - Watch & Earn Platform

A modern web application where users can watch YouTube videos, rate them, and earn money. Built with React, TypeScript, and Supabase.

## 📋 Project Overview

LandTube is a "watch-and-earn" platform that allows users to:
- Watch curated YouTube videos
- Rate videos with a 5-star system
- Earn $5.00 per video review
- Track daily progress and earnings
- Maintain streaks for consistent participation
- Withdraw earnings when reaching goals

## 🚀 Features

### User Authentication
- Secure login system with Supabase Auth
- First-time login flow with password change requirement
- Session management with JWT tokens
- Row Level Security (RLS) for data isolation

### Video Review System
- Random video selection (excludes already-reviewed videos)
- Custom YouTube player with 30-second minimum watch time
- Red/black/green themed UI
- Clean progress bar without numbers
- 5-star rating system
- Real-time earnings tracking

### Dashboard
- Current balance display
- Progress bar to withdrawal goal
- Daily reviews counter (5 per day limit)
- Streak tracking
- Statistics overview

### User Isolation
- Multi-user support with complete data separation
- RLS policies ensuring users only see their own data
- Secure authentication flow

## 🛠️ Tech Stack

### Frontend
- **React 18.3.1** - UI framework
- **TypeScript** - Type safety
- **Vite 5.4.19** - Build tool and dev server
- **Tailwind CSS 3.4.17** - Styling
- **shadcn/ui** - Component library (Radix UI based)
- **React Router 6.30.1** - Client-side routing
- **Lucide React** - Icons

### Backend
- **Supabase** - Backend as a Service
  - PostgreSQL database
  - Authentication
  - Row Level Security
  - Real-time subscriptions
- **YouTube Embed API** - Video player

## 📁 Project Structure

```
landtube-watch-earn-main/
├── src/
│   ├── components/
│   │   ├── ui/                      # shadcn/ui components
│   │   ├── SimpleYouTubePlayer.tsx  # Custom video player
│   │   ├── CompletionModal.tsx      # Review completion dialog
│   │   └── ChangePasswordModal.tsx  # Password change dialog
│   ├── pages/
│   │   ├── Auth.tsx                 # Login page
│   │   ├── Dashboard.tsx            # Main dashboard
│   │   ├── Review.tsx               # Video review page
│   │   └── Index.tsx                # Landing page
│   ├── integrations/
│   │   └── supabase/
│   │       ├── client.ts            # Supabase client config
│   │       └── types.ts             # Database types
│   ├── hooks/                       # Custom React hooks
│   └── lib/                         # Utility functions
├── supabase/
│   └── migrations/                  # Database migrations
└── public/                          # Static assets
```

## 🗄️ Database Schema

### Tables

**profiles**
- `user_id` (uuid, PK)
- `email` (text)
- `balance` (decimal)
- `withdrawal_goal` (decimal)
- `daily_reviews_completed` (integer)
- `total_reviews` (integer)
- `current_streak` (integer)
- `requires_password_change` (boolean)

**videos**
- `id` (uuid, PK)
- `title` (text)
- `youtube_url` (text)
- `thumbnail_url` (text)
- `duration` (integer)
- `earning_amount` (decimal)
- `is_active` (boolean)

**reviews**
- `id` (uuid, PK)
- `user_id` (uuid, FK)
- `video_id` (uuid, FK)
- `rating` (integer, 1-5)
- `earning_amount` (decimal)
- `created_at` (timestamp)
- UNIQUE constraint on (user_id, video_id)

### Functions

**increment_reviews(user_id_param)**
- Increments daily_reviews_completed
- Increments total_reviews
- Updates user's balance

## 🔧 Installation & Setup

### Prerequisites
- Node.js 18+ and npm
- Supabase account
- Git

### Steps

1. **Clone the repository**
```bash
git clone <YOUR_GIT_URL>
cd landtube-watch-earn-main
```

2. **Install dependencies**
```bash
npm install
```

3. **Set up environment variables**
Create a `.env` file in the root directory:
```env
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. **Run database migrations**
```bash
# Connect to your Supabase project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push
```

5. **Start development server**
```bash
npm run dev
```

6. **Build for production**
```bash
npm run build
```

## 📱 Usage Flow

1. **Login/First Access**
   - User logs in with email and temporary password
   - First-time users must change password
   - Profile is created automatically

2. **Dashboard**
   - View current balance and goal progress
   - Check daily reviews completed (0/5)
   - See streak and statistics
   - Click "Start Reviews" to begin

3. **Review Videos**
   - System selects 5 random unreviewed videos
   - Watch each video for minimum 30 seconds
   - Timer counts down automatically
   - Rate video with 1-5 stars
   - Earn $5.00 per review
   - Track progress (Completed/Pending)

4. **Completion**
   - Modal shows total session earnings
   - Balance is updated automatically
   - Daily reviews counter incremented
   - Return to dashboard

## 🎨 Design System

### Colors
- **Primary**: Red gradient (#DC2626 to #991B1B)
- **Success**: Green (#10B981)
- **Background**: Black/Gray-900
- **Accent**: Orange for streaks
- **Warning**: Yellow for goals

### Components
- Custom YouTube player with overlay
- Minimal progress bars
- Card-based layout
- Responsive grid system
- Toast notifications for feedback

## 🔒 Security Features

- Row Level Security (RLS) on all tables
- JWT-based authentication
- Password requirements (minimum 6 characters)
- First-login password change enforcement
- User data isolation
- Secure API keys in environment variables

## 🐛 Known Issues & Solutions

### Timer Reset Bug (SOLVED)
**Problem**: Timer didn't reset between videos  
**Solution**: Added useEffect with videoUrl dependency

### Play Button Synchronization (SOLVED)
**Problem**: Play button and video weren't synchronized  
**Solution**: Changed autoplay parameter based on isTimerActive state

### Multiple Click Protection (SOLVED)
**Problem**: Multiple clicks could skip videos  
**Solution**: Implemented isSubmitting state flag

### Random Video Selection (IMPLEMENTED)
**Problem**: Videos weren't randomized or filtered  
**Solution**: Multi-step query with exclusion and shuffling

## 📊 Future Enhancements

- [ ] Withdrawal system implementation
- [ ] Payment gateway integration
- [ ] Admin panel for video management
- [ ] Advanced analytics dashboard
- [ ] Mobile app (React Native)
- [ ] Referral system
- [ ] Bonus streaks and achievements
- [ ] Video categories and tags
- [ ] User preferences and settings

## 🤝 Contributing

This is a private project. For questions or suggestions, contact the project owner.

## 📄 License

Private project - All rights reserved

## 🔗 Links

- **Lovable Project**: https://lovable.dev/projects/166721bb-bb36-4984-91a9-e60b5ccea914
- **Documentation**: See `/docs` folder for detailed guides

## 📞 Support

For technical issues or questions, please contact the development team.

---

**Built with ❤️ using Lovable, React, TypeScript, and Supabase**
