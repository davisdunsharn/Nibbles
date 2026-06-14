#!/usr/bin/env node

// This script confirms all unconfirmed users in Supabase
// You need to have SUPABASE_ACCESS_TOKEN set in your environment

const projectRef = 'yxbqcafkifdtpjcqrlge'
const accessToken = process.env.SUPABASE_ACCESS_TOKEN

if (!accessToken) {
  console.error('ERROR: SUPABASE_ACCESS_TOKEN environment variable is not set')
  console.log('Get your access token from: https://app.supabase.com/account/tokens')
  process.exit(1)
}

async function confirmAllUsers() {
  try {
    // Get all users
    const usersResponse = await fetch(
      `https://api.supabase.com/v1/projects/${projectRef}/auth/users`,
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        }
      }
    )

    if (!usersResponse.ok) {
      throw new Error(`Failed to fetch users: ${usersResponse.statusText}`)
    }

    const { users } = await usersResponse.json()
    console.log(`Found ${users.length} users`)

    let confirmedCount = 0

    for (const user of users) {
      if (!user.email_confirmed_at) {
        console.log(`Confirming user: ${user.email}`)
        
        const updateResponse = await fetch(
          `https://api.supabase.com/v1/projects/${projectRef}/auth/users/${user.id}`,
          {
            method: 'PUT',
            headers: {
              'Authorization': `Bearer ${accessToken}`,
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({
              email_confirm: true
            })
          }
        )

        if (!updateResponse.ok) {
          console.error(`Failed to confirm ${user.email}: ${updateResponse.statusText}`)
        } else {
          console.log(`✓ Confirmed: ${user.email}`)
          confirmedCount++
        }
      } else {
        console.log(`✓ Already confirmed: ${user.email}`)
      }
    }

    console.log(`\n✓ Successfully confirmed ${confirmedCount} users`)
  } catch (error) {
    console.error('Error:', error.message)
    process.exit(1)
  }
}

confirmAllUsers()
