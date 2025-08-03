import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL
const supabaseAnonKey = import.meta.env.PUBLIC_SUPABASE_ANON_KEY

// Debug logging
console.log('Environment check:', {
  url: supabaseUrl ? 'Present' : 'Missing',
  key: supabaseAnonKey ? 'Present' : 'Missing',
  urlValue: supabaseUrl?.substring(0, 30) + '...',
  keyValue: supabaseAnonKey?.substring(0, 20) + '...'
})

if (!supabaseUrl) {
  console.error('PUBLIC_SUPABASE_URL is missing!')
}
if (!supabaseAnonKey) {
  console.error('PUBLIC_SUPABASE_ANON_KEY is missing!')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey) 