import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Star, CheckCircle2, Flame, Trophy, Lock } from "lucide-react";
import { toast } from "sonner";
import { ChangePasswordModal } from "@/components/ChangePasswordModal";

interface Profile {
  user_id: string;
  email: string;
  display_name: string | null;
  balance: number;
  withdrawal_goal: number;
  daily_reviews_completed: number;
  total_reviews: number;
  current_streak: number;
  requires_password_change: boolean;
}

interface DailyListProgress {
  videos_completed: number;
  is_completed: boolean;
}

const Dashboard = () => {
  const navigate = useNavigate();
  const [profile, setProfile] = useState<Profile | null>(null);
  const [dailyProgress, setDailyProgress] = useState<DailyListProgress>({ 
    videos_completed: 0, 
    is_completed: false 
  });
  const [loading, setLoading] = useState(true);
  const [showPasswordModal, setShowPasswordModal] = useState(false);

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    try {
      const { data: { session } } = await supabase.auth.getSession();

      if (!session) {
        navigate("/auth");
        return;
      }

      const { data: profileData, error } = await supabase
        .from("profiles")
        .select("*")
        .eq("user_id", session.user.id)
        .single();

      if (error) throw error;

      setProfile(profileData);

      // Check if there's an active list for today
      const { data: listData } = await supabase
        .from("daily_video_lists")
        .select("videos_completed, is_completed")
        .eq("user_id", session.user.id)
        .eq("list_date", new Date().toISOString().split('T')[0])
        .maybeSingle();

      if (listData) {
        setDailyProgress({
          videos_completed: listData.videos_completed || 0,
          is_completed: listData.is_completed || false
        });
      } else {
        // No list created yet today
        setDailyProgress({ videos_completed: 0, is_completed: false });
      }

      if (profileData.requires_password_change) {
        setShowPasswordModal(true);
      }
    } catch (error) {
      toast.error("Error loading profile");
      navigate("/auth");
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat("pt-BR", {
      style: "currency",
      currency: "USD",
    }).format(value);
  };

  const progressPercentage = profile
    ? (profile.balance / profile.withdrawal_goal) * 100
    : 0;

  // Use daily list progress for display, but check is_completed for button state
  const videosWatchedToday = dailyProgress.videos_completed;
  const remainingReviews = 5 - videosWatchedToday;
  const isListCompleted = dailyProgress.is_completed;

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="text-muted-foreground">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen p-4 md:p-8">
      <div className="max-w-6xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-3xl md:text-4xl font-bold">
              Hello! Ready to earn today?
            </h1>
            <p className="text-muted-foreground mt-1">
              Review videos, accumulate points, and reach your goal.
            </p>
          </div>
          <div className="text-left md:text-right">
            <p className="text-sm text-muted-foreground">{profile?.email}</p>
            <p className="text-xs text-muted-foreground">
              {new Date().toLocaleDateString("pt-BR", {
                weekday: "long",
                year: "numeric",
                month: "long",
                day: "numeric",
              })}
            </p>
          </div>
        </div>

        {/* Progress Card */}
        <Card className="p-6 md:p-8 space-y-4">
          <div className="flex justify-between items-start">
            <h2 className="text-xl font-semibold">Progress to Goal</h2>
            <div className="text-right">
              <div className="text-3xl md:text-4xl font-bold text-primary">
                {formatCurrency(profile?.balance || 0)}
              </div>
            </div>
          </div>
          <Progress value={progressPercentage} className="h-3" />
          <div className="flex justify-between text-sm text-muted-foreground">
            <span>{progressPercentage.toFixed(1)}% completed</span>
            <span>
              {formatCurrency(
                (profile?.withdrawal_goal || 0) - (profile?.balance || 0)
              )}{" "}
              remaining
            </span>
          </div>
          <Button
            className="w-full md:w-auto"
            size="lg"
            disabled={progressPercentage < 100}
          >
            <Lock className="w-4 h-4 mr-2" />
            Withdrawal Unavailable
          </Button>
        </Card>

        {/* Stats Grid */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Card className="p-4 md:p-6 space-y-2">
            <div className="flex items-center gap-1 md:gap-2 text-primary">
              <Star className="w-4 h-4 md:w-5 md:h-5 flex-shrink-0" />
              <h3 className="font-semibold text-xs md:text-base">Videos Today</h3>
            </div>
            <div className="text-2xl md:text-3xl font-bold">
              {videosWatchedToday}/5
            </div>
            <p className="text-xs md:text-sm text-muted-foreground">
              {isListCompleted ? "List completed! ✅" : `${remainingReviews} remaining`}
            </p>
          </Card>

          <Card className="p-4 md:p-6 space-y-2">
            <div className="flex items-center gap-1 md:gap-2 text-success">
              <CheckCircle2 className="w-4 h-4 md:w-5 md:h-5 flex-shrink-0" />
              <h3 className="font-semibold text-xs md:text-base">Total Reviews</h3>
            </div>
            <div className="text-2xl md:text-3xl font-bold">
              {profile?.total_reviews || 0}
            </div>
            <p className="text-xs md:text-sm text-muted-foreground">completed</p>
          </Card>

          <Card className="p-4 md:p-6 space-y-2">
            <div className="flex items-center gap-1 md:gap-2 text-orange-500">
              <Flame className="w-4 h-4 md:w-5 md:h-5 flex-shrink-0" />
              <h3 className="font-semibold text-xs md:text-base">Day Streak</h3>
            </div>
            <div className="text-2xl md:text-3xl font-bold">
              {profile?.current_streak || 0}
            </div>
            <p className="text-xs md:text-sm text-muted-foreground">consecutive</p>
          </Card>

          <Card className="p-4 md:p-6 space-y-2">
            <div className="flex items-center gap-1 md:gap-2 text-yellow-500">
              <Trophy className="w-4 h-4 md:w-5 md:h-5 flex-shrink-0" />
              <h3 className="font-semibold text-xs md:text-base">Withdrawal Goal</h3>
            </div>
            <div className="text-lg md:text-3xl font-bold break-words leading-tight">
              {formatCurrency(profile?.withdrawal_goal || 0)}
            </div>
            <p className="text-xs md:text-sm text-muted-foreground">
              {progressPercentage.toFixed(1)}%
            </p>
          </Card>
        </div>

        {/* CTA Card */}
        <Card className="p-8 text-center space-y-4 bg-gradient-to-br from-card to-secondary">
          <div className="space-y-2">
            {isListCompleted ? (
              <>
                <h2 className="text-2xl md:text-3xl font-bold text-success">
                  Daily list completed! 🎉
                </h2>
                <p className="text-muted-foreground">
                  You earned $25.00 today. Come back tomorrow for a new list!
                </p>
              </>
            ) : videosWatchedToday > 0 ? (
              <>
                <h2 className="text-2xl md:text-3xl font-bold">
                  Continue your list!{" "}
                  <span className="text-primary">
                    {videosWatchedToday}/5 videos watched
                  </span>
                </h2>
                <p className="text-muted-foreground">
                  Complete all 5 videos to earn $25.00
                </p>
                <p className="text-xs text-yellow-600">
                  ⚠️ Earnings are credited only after completing the entire list
                </p>
              </>
            ) : (
              <>
                <h2 className="text-2xl md:text-3xl font-bold">
                  Earn{" "}
                  <span className="text-success">
                    {formatCurrency(25)}
                  </span>{" "}
                  today!
                </h2>
                <p className="text-muted-foreground">
                  Watch and review 5 videos to complete your daily list.
                </p>
              </>
            )}
          </div>
          <Button
            size="lg"
            className="text-lg px-8 h-14"
            onClick={() => navigate("/review")}
            disabled={isListCompleted}
          >
            {isListCompleted 
              ? "Completed ✓" 
              : videosWatchedToday > 0 
              ? "Continue List" 
              : "Start Reviews"}
          </Button>
        </Card>
      </div>

      <ChangePasswordModal
        open={showPasswordModal}
        onOpenChange={setShowPasswordModal}
        onSuccess={() => {
          setShowPasswordModal(false);
          checkAuth();
        }}
      />
    </div>
  );
};

export default Dashboard;
