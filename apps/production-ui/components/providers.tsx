"use client"

import * as React from "react"
import { ClerkProvider } from "@clerk/nextjs"
import { dark } from "@clerk/themes"
import { CreditsProvider } from "@/lib/contexts/credits-context"

export function Providers({
    children,
    publishableKey
}: {
    children: React.ReactNode
    publishableKey?: string
}) {
    if (!publishableKey) {
        return <CreditsProvider noAuth>{children}</CreditsProvider>
    }

    return (
        <ClerkProvider
            publishableKey={publishableKey}
            appearance={{
                baseTheme: dark,
                variables: {
                    colorPrimary: "oklch(0.55 0.15 240)",
                    colorBackground: "oklch(0.12 0.02 240)",
                },
            }}
        >
            <CreditsProvider>{children}</CreditsProvider>
        </ClerkProvider>
    )
}
