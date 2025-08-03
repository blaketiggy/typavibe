import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL
const supabaseAnonKey = import.meta.env.PUBLIC_SUPABASE_ANON_KEY

// Debug environment variables
console.log('Supabase URL present:', !!supabaseUrl);
console.log('Supabase Anon Key present:', !!supabaseAnonKey);
console.log('Supabase URL (first 20 chars):', supabaseUrl ? supabaseUrl.substring(0, 20) + '...' : 'undefined');
console.log('Supabase Anon Key (first 20 chars):', supabaseAnonKey ? supabaseAnonKey.substring(0, 20) + '...' : 'undefined');

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('Missing Supabase environment variables!');
  console.error('PUBLIC_SUPABASE_URL:', supabaseUrl);
  console.error('PUBLIC_SUPABASE_ANON_KEY:', supabaseAnonKey);
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey) 