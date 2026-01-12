"""
VirusTotal API Integration
"""
import logging
import os
import requests
import time
from typing import Dict, Any

logger = logging.getLogger(__name__)


class VirusTotalChecker:
    """Check APK hash against VirusTotal database"""
    
    def __init__(self, api_key=None):
        self.api_key = api_key or os.environ.get('VIRUSTOTAL_API_KEY')
        self.base_url = 'https://www.virustotal.com/vtapi/v2'
        self.enabled = bool(self.api_key)
        
        if not self.enabled:
            logger.warning("VirusTotal API key not configured - checks disabled")
        else:
            logger.info("VirusTotal integration enabled")
    
    def check_hash(self, file_hash: str) -> Dict[str, Any]:
        """
        Check file hash against VirusTotal database
        """
        if not self.enabled:
            return {
                'available': False,
                'message': 'VirusTotal API key not configured'
            }
        
        try:
            # Query VirusTotal API
            params = {
                'apikey': self.api_key,
                'resource': file_hash
            }
            
            response = requests.get(
                f'{self.base_url}/file/report',
                params=params,
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                
                if data.get('response_code') == 1:
                    # File found in VT database
                    positives = data.get('positives', 0)
                    total = data.get('total', 0)
                    
                    return {
                        'available': True,
                        'detected': positives > 0,
                        'positives': positives,
                        'total': total,
                        'detection_ratio': f"{positives}/{total}",
                        'scan_date': data.get('scan_date'),
                        'permalink': data.get('permalink'),
                        'scans': self._parse_scan_results(data.get('scans', {}))
                    }
                else:
                    # File not found in VT database
                    return {
                        'available': True,
                        'detected': False,
                        'message': 'File not found in VirusTotal database',
                        'positives': 0,
                        'total': 0
                    }
            elif response.status_code == 204:
                # Rate limit exceeded
                return {
                    'available': False,
                    'error': 'VirusTotal rate limit exceeded'
                }
            else:
                return {
                    'available': False,
                    'error': f'VirusTotal API error: {response.status_code}'
                }
        
        except requests.Timeout:
            logger.error("VirusTotal API timeout")
            return {
                'available': False,
                'error': 'VirusTotal API timeout'
            }
        except Exception as e:
            logger.error(f"VirusTotal check failed: {str(e)}")
            return {
                'available': False,
                'error': str(e)
            }
    
    def _parse_scan_results(self, scans: Dict) -> List[Dict]:
        """Parse and filter scan results from multiple AV engines"""
        results = []
        
        for engine, result in scans.items():
            if result.get('detected'):
                results.append({
                    'engine': engine,
                    'result': result.get('result'),
                    'version': result.get('version')
                })
        
        # Return top 10 detections
        return results[:10]
    
    def submit_file(self, file_path: str) -> Dict[str, Any]:
        """
        Submit file to VirusTotal for scanning (if not already present)
        Note: This requires a valid API key and may take time to process
        """
        if not self.enabled:
            return {
                'success': False,
                'message': 'VirusTotal API key not configured'
            }
        
        try:
            url = 'https://www.virustotal.com/vtapi/v2/file/scan'
            
            with open(file_path, 'rb') as f:
                files = {'file': f}
                params = {'apikey': self.api_key}
                
                response = requests.post(
                    url,
                    files=files,
                    params=params,
                    timeout=60
                )
            
            if response.status_code == 200:
                data = response.json()
                return {
                    'success': True,
                    'scan_id': data.get('scan_id'),
                    'permalink': data.get('permalink'),
                    'message': 'File submitted successfully. Scan may take a few minutes.'
                }
            else:
                return {
                    'success': False,
                    'error': f'Submission failed: {response.status_code}'
                }
        
        except Exception as e:
            logger.error(f"File submission failed: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
