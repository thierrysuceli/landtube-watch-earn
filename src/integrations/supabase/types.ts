export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.5"
  }
  public: {
    Tables: {
      daily_video_lists: {
        Row: {
          created_at: string | null
          current_video_index: number | null
          id: string
          is_completed: boolean | null
          list_date: string
          updated_at: string | null
          user_id: string
          video_ids: string[]
          videos_completed: number | null
        }
        Insert: {
          created_at?: string | null
          current_video_index?: number | null
          id?: string
          is_completed?: boolean | null
          list_date?: string
          updated_at?: string | null
          user_id: string
          video_ids: string[]
          videos_completed?: number | null
        }
        Update: {
          created_at?: string | null
          current_video_index?: number | null
          id?: string
          is_completed?: boolean | null
          list_date?: string
          updated_at?: string | null
          user_id?: string
          video_ids?: string[]
          videos_completed?: number | null
        }
        Relationships: []
      }
      profiles: {
        Row: {
          balance: number | null
          created_at: string | null
          current_streak: number | null
          daily_reviews_completed: number | null
          display_name: string | null
          email: string
          id: string
          last_review_date: string | null
          requires_password_change: boolean | null
          total_reviews: number | null
          updated_at: string | null
          user_id: string
          withdrawal_goal: number | null
        }
        Insert: {
          balance?: number | null
          created_at?: string | null
          current_streak?: number | null
          daily_reviews_completed?: number | null
          display_name?: string | null
          email: string
          id?: string
          last_review_date?: string | null
          requires_password_change?: boolean | null
          total_reviews?: number | null
          updated_at?: string | null
          user_id: string
          withdrawal_goal?: number | null
        }
        Update: {
          balance?: number | null
          created_at?: string | null
          current_streak?: number | null
          daily_reviews_completed?: number | null
          display_name?: string | null
          email?: string
          id?: string
          last_review_date?: string | null
          requires_password_change?: boolean | null
          total_reviews?: number | null
          updated_at?: string | null
          user_id?: string
          withdrawal_goal?: number | null
        }
        Relationships: []
      }
      reviews: {
        Row: {
          completed_at: string | null
          earning_amount: number
          id: string
          rating: number
          user_id: string
          video_id: string
        }
        Insert: {
          completed_at?: string | null
          earning_amount: number
          id?: string
          rating: number
          user_id: string
          video_id: string
        }
        Update: {
          completed_at?: string | null
          earning_amount?: number
          id?: string
          rating?: number
          user_id?: string
          video_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "reviews_video_id_fkey"
            columns: ["video_id"]
            isOneToOne: false
            referencedRelation: "videos"
            referencedColumns: ["id"]
          },
        ]
      }
      videos: {
        Row: {
          created_at: string | null
          duration: number | null
          earning_amount: number | null
          id: string
          is_active: boolean | null
          thumbnail_url: string | null
          title: string
        }
        Insert: {
          created_at?: string | null
          duration?: number | null
          earning_amount?: number | null
          id?: string
          is_active?: boolean | null
          thumbnail_url?: string | null
          title: string
        }
        Update: {
          created_at?: string | null
          duration?: number | null
          earning_amount?: number | null
          id?: string
          is_active?: boolean | null
          thumbnail_url?: string | null
          title?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      get_or_create_daily_list: {
        Args: { user_id_param: string }
        Returns: {
          list_id: string
          video_ids: string[]
          current_video_index: number
          videos_completed: number
          is_completed: boolean
          list_date: string
        }[]
      }
      increment_reviews: {
        Args: { user_id_param: string }
        Returns: undefined
      }
      update_list_progress: {
        Args: { 
          user_id_param: string
          video_index_param: number
        }
        Returns: boolean
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
