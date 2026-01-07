import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'
import AppAzure from './App-azure.jsx'
import AppGCP from './App-gcp.jsx'

createRoot(document.getElementById('root')).render(
    <AppGCP />
)
