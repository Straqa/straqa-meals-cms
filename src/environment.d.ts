declare global {
  namespace NodeJS {
    interface ProcessEnv {
      PAYLOAD_SECRET: string
      DATABASE_URI: string
      NEXT_PUBLIC_SERVER_URL: string
      VERCEL_PROJECT_PRODUCTION_URL: string
      // s3
      S3_ENDPOINT: string
      S3_FORCE_PATH_STYLE: string
      S3_REGION: string
      S3_PREFIX: string
      S3_ACCESS_KEY_ID: string
      S3_SECRET_ACCESS_KEY: string
      S3_BUCKET: string
      // smtp
      SMTP_FROM_ADDRESS: string
      SMTP_FROM_NAME: string
      SMTP_HOST: string
      SMTP_PORT: number
      SMTP_USER: string
      SMTP_PASS: string
    }
  }
}

// If this file has no import/export statements (i.e. is a script)
// convert it into a module by adding an empty export statement.
export {}
