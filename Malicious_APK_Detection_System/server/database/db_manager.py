"""
Database Manager for storing scan results
"""
import sqlite3
import json
import logging
from datetime import datetime
from typing import Dict, List, Any, Optional

logger = logging.getLogger(__name__)


class DatabaseManager:
    """Manages SQLite database for scan history"""
    
    def __init__(self, db_path='database/scans.db'):
        self.db_path = db_path
        self._init_database()
    
    def _init_database(self):
        """Initialize database with required tables"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Create scans table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS scans (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    scan_id TEXT UNIQUE,
                    filename TEXT,
                    file_hash TEXT UNIQUE,
                    timestamp TEXT,
                    verdict TEXT,
                    risk_score INTEGER,
                    package_name TEXT,
                    app_name TEXT,
                    result_json TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            # Create index on hash for quick lookups
            cursor.execute('''
                CREATE INDEX IF NOT EXISTS idx_file_hash 
                ON scans(file_hash)
            ''')
            
            # Create index on verdict for statistics
            cursor.execute('''
                CREATE INDEX IF NOT EXISTS idx_verdict 
                ON scans(verdict)
            ''')
            
            conn.commit()
            conn.close()
            logger.info(f"Database initialized at {self.db_path}")
        except Exception as e:
            logger.error(f"Database initialization failed: {str(e)}")
    
    def save_scan(self, scan_result: Dict[str, Any]) -> bool:
        """Save scan result to database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT OR REPLACE INTO scans 
                (scan_id, filename, file_hash, timestamp, verdict, risk_score, 
                 package_name, app_name, result_json)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                scan_result.get('scan_id'),
                scan_result.get('filename'),
                scan_result.get('file_hash'),
                scan_result.get('timestamp'),
                scan_result.get('verdict'),
                scan_result.get('risk_score'),
                scan_result.get('apk_info', {}).get('package_name'),
                scan_result.get('apk_info', {}).get('app_name'),
                json.dumps(scan_result)
            ))
            
            conn.commit()
            conn.close()
            logger.info(f"Scan saved: {scan_result.get('scan_id')}")
            return True
        except Exception as e:
            logger.error(f"Failed to save scan: {str(e)}")
            return False
    
    def get_scan_by_hash(self, file_hash: str) -> Optional[Dict[str, Any]]:
        """Get scan result by file hash (for caching)"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT result_json FROM scans 
                WHERE file_hash = ?
                ORDER BY created_at DESC
                LIMIT 1
            ''', (file_hash,))
            
            row = cursor.fetchone()
            conn.close()
            
            if row:
                return json.loads(row[0])
            return None
        except Exception as e:
            logger.error(f"Failed to get scan by hash: {str(e)}")
            return None
    
    def get_recent_scans(self, limit: int = 50) -> List[Dict[str, Any]]:
        """Get recent scans"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT scan_id, filename, verdict, risk_score, 
                       package_name, app_name, timestamp
                FROM scans
                ORDER BY created_at DESC
                LIMIT ?
            ''', (limit,))
            
            rows = cursor.fetchall()
            conn.close()
            
            scans = []
            for row in rows:
                scans.append({
                    'scan_id': row[0],
                    'filename': row[1],
                    'verdict': row[2],
                    'risk_score': row[3],
                    'package_name': row[4],
                    'app_name': row[5],
                    'timestamp': row[6]
                })
            
            return scans
        except Exception as e:
            logger.error(f"Failed to get recent scans: {str(e)}")
            return []
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get statistics about scans"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Total scans
            cursor.execute('SELECT COUNT(*) FROM scans')
            total_scans = cursor.fetchone()[0]
            
            # Verdict counts
            cursor.execute('''
                SELECT verdict, COUNT(*) 
                FROM scans 
                GROUP BY verdict
            ''')
            verdict_counts = dict(cursor.fetchall())
            
            # Average risk score
            cursor.execute('SELECT AVG(risk_score) FROM scans')
            avg_risk = cursor.fetchone()[0] or 0
            
            conn.close()
            
            return {
                'total_scans': total_scans,
                'malicious': verdict_counts.get('Malicious', 0),
                'suspicious': verdict_counts.get('Suspicious', 0),
                'safe': verdict_counts.get('Safe', 0),
                'average_risk_score': round(avg_risk, 2)
            }
        except Exception as e:
            logger.error(f"Failed to get statistics: {str(e)}")
            return {
                'total_scans': 0,
                'malicious': 0,
                'suspicious': 0,
                'safe': 0,
                'average_risk_score': 0
            }
    
    def delete_old_scans(self, days: int = 30) -> int:
        """Delete scans older than specified days"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                DELETE FROM scans 
                WHERE created_at < datetime('now', '-' || ? || ' days')
            ''', (days,))
            
            deleted = cursor.rowcount
            conn.commit()
            conn.close()
            
            logger.info(f"Deleted {deleted} old scans")
            return deleted
        except Exception as e:
            logger.error(f"Failed to delete old scans: {str(e)}")
            return 0
