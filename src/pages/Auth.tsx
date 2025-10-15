import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card } from "@/components/ui/card";
import { Play } from "lucide-react";
import { toast } from "sonner";

const Auth = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        toast.error("Invalid credentials");
        return;
      }

      if (data.user) {
        // Check if profile exists
        const { data: profile } = await supabase
          .from("profiles")
          .select("*")
          .eq("user_id", data.user.id)
          .maybeSingle();

        if (!profile) {
          // Create profile for first-time login
          await supabase.from("profiles").insert({
            user_id: data.user.id,
            email: data.user.email!,
            requires_password_change: true,
          });
        }

        navigate("/dashboard");
      }
    } catch (error) {
      toast.error("Error logging in");
    } finally {
      setLoading(false);
    }
  };

  const handleFirstLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        toast.error("Invalid temporary credentials");
        return;
      }

      if (data.user) {
        // Check if profile exists, create if not
        const { data: profile } = await supabase
          .from("profiles")
          .select("*")
          .eq("user_id", data.user.id)
          .maybeSingle();

        if (!profile) {
          await supabase.from("profiles").insert({
            user_id: data.user.id,
            email: data.user.email!,
            requires_password_change: true,
          });
        } else {
          await supabase
            .from("profiles")
            .update({ requires_password_change: true })
            .eq("user_id", data.user.id);
        }

        navigate("/dashboard");
      }
    } catch (error) {
      toast.error("Error during first login");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <Card className="w-full max-w-md p-8 space-y-6">
        <div className="text-center space-y-2">
          <div className="flex items-center justify-center gap-2 text-3xl font-bold">
            <Play className="w-8 h-8 text-primary fill-primary" />
            <span>LandTube</span>
          </div>
          <p className="text-muted-foreground">
            Sign in to your account to continue
          </p>
        </div>

        <Tabs defaultValue="login" className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="login">Login</TabsTrigger>
            <TabsTrigger value="first">First Login</TabsTrigger>
          </TabsList>

          <TabsContent value="login" className="space-y-4 mt-6">
            <form onSubmit={handleLogin} className="space-y-4">
              <div className="space-y-2">
                <Input
                  type="email"
                  placeholder="Your email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  className="h-12"
                />
              </div>
              <div className="space-y-2">
                <Input
                  type="password"
                  placeholder="Your password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="h-12"
                />
              </div>
              <div className="text-right">
                <button
                  type="button"
                  className="text-sm text-muted-foreground hover:text-foreground"
                >
                  Forgot password?
                </button>
              </div>
              <Button
                type="submit"
                className="w-full h-12 text-lg"
                disabled={loading}
              >
                Sign In
              </Button>
            </form>
          </TabsContent>

          <TabsContent value="first" className="space-y-4 mt-6">
            <form onSubmit={handleFirstLogin} className="space-y-4">
              <div className="space-y-2">
                <Input
                  type="email"
                  placeholder="Your email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  className="h-12"
                />
              </div>
              <div className="space-y-2">
                <Input
                  type="password"
                  placeholder="Temporary password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="h-12"
                />
              </div>
              <Button
                type="submit"
                className="w-full h-12 text-lg"
                disabled={loading}
              >
                Sign In
              </Button>
              <p className="text-sm text-muted-foreground text-center">
                First time access?{" "}
                <span className="text-primary">Validate your credentials</span>
              </p>
            </form>
          </TabsContent>
        </Tabs>
      </Card>
    </div>
  );
};

export default Auth;
