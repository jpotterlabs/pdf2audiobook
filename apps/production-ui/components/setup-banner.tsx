"use client"

import * as React from "react"

import { AlertCircle } from "lucide-react"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"

export function SetupBanner() {
  const hasClerkKeys = !!process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
  const hasApiUrl = !!process.env.NEXT_PUBLIC_API_URL

  if (hasClerkKeys && hasApiUrl) return null

  return (
    <Alert variant="destructive" className="mb-8">
      <AlertCircle className="h-4 w-4" />
      <AlertTitle>Setup Required</AlertTitle>
      <AlertDescription className="space-y-2">
        <p>This application requires environment variables to be configured:</p>
        <ul className="list-disc list-inside space-y-1 text-sm">
          {!hasClerkKeys && (
            <li>
              <strong>NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY</strong> and <strong>CLERK_SECRET_KEY</strong> - Get these from{" "}
              <a
                href="https://dashboard.clerk.com/last-active?path=api-keys"
                target="_blank"
                rel="noopener noreferrer"
                className="underline"
              >
                Clerk Dashboard
              </a>
            </li>
          )}
          {!hasApiUrl && (
            <li>
              <strong>NEXT_PUBLIC_API_URL</strong> - Your backend API URL (defaults to http://localhost:8000)
            </li>
          )}
        </ul>
      </AlertDescription>
    </Alert>
  )
}
