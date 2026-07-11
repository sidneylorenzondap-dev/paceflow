import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://jjxwczjynvjvkgjcyiyo.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpqeHdjemp5bnZqdmtnamN5aXlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyMTA2NzAsImV4cCI6MjA5Njc4NjY3MH0.z13h_ajz031a_BVX7ZTpZIb55QTUS0ys_93P74i_SAQ';
const supabase = createClient(supabaseUrl, supabaseKey);

async function main() {
  const email = `test${Date.now()}@example.com`;
  const password = 'password123';
  
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
  });

  if (error) {
    console.error('Sign up error:', error);
    return;
  }

  console.log('Token:', data.session?.access_token);
}

main();
