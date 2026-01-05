import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'
import AppAzure from './App-azure.jsx'

createRoot(document.getElementById('root')).render(
    <AppAzure />
)
