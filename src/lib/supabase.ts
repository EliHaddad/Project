'use client';
import {createClient, type SupabaseClient} from '@supabase/supabase-js';
let instance: SupabaseClient | undefined;
export function configured() {return Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY);}
export function supabase() {
  if (!configured()) throw new Error('Supabase configuration missing');
  return instance ??= createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!,process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!);
}
