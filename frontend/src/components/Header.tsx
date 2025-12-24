'use client'

import { UserButton, SignedIn, SignedOut, useAuth } from '@clerk/nextjs'
import Link from 'next/link'
import { FileText, Upload, History, CreditCard, Coins } from 'lucide-react'
import { useEffect, useState } from 'react'
import { getCurrentUser } from '../lib/api'

export default function Header() {
  const { getToken, userId } = useAuth()
  const [credits, setCredits] = useState<number | null>(null)
  const [creditsError, setCreditsError] = useState(false)

  useEffect(() => {
    const fetchCredits = async () => {
      if (!userId) return
      try {
        const token = await getToken()
        if (!token) return
        const user = await getCurrentUser(token)
        setCredits(user.credit_balance)
        setCreditsError(false)
      } catch (error) {
        console.error('Failed to fetch user credits:', error)
        setCreditsError(true)
      }
    }

    fetchCredits()
  }, [userId, getToken])

  return (
    <header className="bg-white shadow-sm border-b">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center space-x-2">
            <FileText className="h-8 w-8 text-blue-600" />
            <span className="text-xl font-bold text-gray-900">
              PDF2AudioBook
            </span>
          </Link>

          {/* Navigation */}
          <nav className="hidden md:flex space-x-8">
            <SignedIn>
              <>
                <Link
                  href="/upload"
                  className="text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium flex items-center space-x-1"
                >
                  <Upload className="h-4 w-4" />
                  <span>Upload</span>
                </Link>
                <Link
                  href="/jobs"
                  className="text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium flex items-center space-x-1"
                >
                  <History className="h-4 w-4" />
                  <span>My Jobs</span>
                </Link>
                <Link
                  href="/pricing"
                  className="text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium flex items-center space-x-1"
                >
                  <CreditCard className="h-4 w-4" />
                  <span>Pricing</span>
                </Link>
              </>
            </SignedIn>
            <SignedOut>
              <Link
                href="/pricing"
                className="text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium"
              >
                Pricing
              </Link>
            </SignedOut>
          </nav>

          {/* User Button & Credits */}
          <div className="flex items-center space-x-4">
            <SignedIn>
              {credits !== null && !creditsError && (
                <div className="hidden sm:flex items-center px-3 py-1 bg-blue-50 text-blue-700 rounded-full text-sm font-medium border border-blue-100 mr-2">
                  <Coins className="h-4 w-4 mr-1.5" />
                  {credits} Credits
                </div>
              )}
              {creditsError && (
                <div className="hidden sm:flex items-center px-3 py-1 bg-gray-50 text-gray-600 rounded-full text-sm font-medium border border-gray-200 mr-2">
                  <Coins className="h-4 w-4 mr-1.5 opacity-50" />
                  --
                </div>
              )}
              <UserButton afterSignOutUrl="/" />
            </SignedIn>
            <SignedOut>
              <div className="flex space-x-2">
                <Link
                  href="/sign-in"
                  className="text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium"
                >
                  Sign In
                </Link>
                <Link
                  href="/sign-up"
                  className="bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded-md text-sm font-medium"
                >
                  Sign Up
                </Link>
              </div>
            </SignedOut>
          </div>
        </div>
      </div>
    </header>
  )
}
