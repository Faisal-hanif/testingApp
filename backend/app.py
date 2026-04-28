from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
from bs4 import BeautifulSoup
import re
from datetime import datetime
from urllib.parse import urljoin, urlparse
import time
from transformers import AutoTokenizer, AutoModelForCausalLM
from peft import PeftModel
import torch

print("🤖 Loading LLM model...")

llm_adapter_path = r"C:\Users\dt\Desktop\sqa-agent\llm-finetune\sqa-llm-finetuned"

# Load base model WITHOUT device_map initially
base_model = AutoModelForCausalLM.from_pretrained(
    "TinyLlama/TinyLlama-1.1B-Chat-v1.0",
    torch_dtype=torch.float16
)

# Load tokenizer
llm_tokenizer = AutoTokenizer.from_pretrained("TinyLlama/TinyLlama-1.1B-Chat-v1.0")
llm_tokenizer.pad_token = llm_tokenizer.eos_token

# Load adapter
try:
    llm_model = PeftModel.from_pretrained(base_model, llm_adapter_path)
    print("✅ Fine-tuned model loaded!")
except Exception as e:
    print(f"⚠️ Adapter load failed: {e}")
    print("✅ Using base model without fine-tuning")
    llm_model = base_model

# Move to CPU after loading
print("✅ LLM model ready!")




app = Flask(__name__)
CORS(app)

def is_valid_url(url):
    try:
        result = urlparse(url)
        return all([result.scheme, result.netloc])
    except:
        return False

def get_absolute_url(base_url, link):
    if link.startswith('http'):
        return link
    elif link.startswith('//'):
        return 'https:' + link
    elif link.startswith('/'):
        return urljoin(base_url, link)
    elif link.startswith('#'):
        return None
    else:
        return urljoin(base_url, link)

def get_page_text(soup):
    for script in soup(["script", "style", "nav", "footer", "iframe"]):
        script.decompose()
    text = soup.get_text()
    lines = (line.strip() for line in text.splitlines())
    chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
    text = ' '.join(chunk for chunk in chunks if chunk)
    return text[:5000]

# Emotional Analysis
def analyze_emotional_response(url, soup, headers):
    try:
        r = requests.get(url, timeout=5)
        response_time = time.time() - time.time()
    except:
        response_time = 2.0
    
    trust_score = 0
    trust_details = []
    
    if url.startswith('https'):
        trust_score += 25
        trust_details.append("SSL Certificate present")
    else:
        trust_details.append("Missing SSL certificate")
    
    if soup.find('a', href=re.compile(r'mailto:')) or soup.find('a', href=re.compile(r'contact')) or soup.find('a', text=re.compile(r'Contact', re.I)):
        trust_score += 15
        trust_details.append("Contact information found")
    else:
        trust_details.append("No clear contact information")
    
    if soup.find('a', href=re.compile(r'about', re.I)) or soup.find('a', text=re.compile(r'About', re.I)):
        trust_score += 10
        trust_details.append("About page exists")
    else:
        trust_details.append("No About page found")
    
    social_patterns = ['facebook', 'twitter', 'instagram', 'linkedin', 'youtube']
    for pattern in social_patterns:
        if soup.find('a', href=re.compile(pattern, re.I)):
            trust_score += 5
    trust_score = min(trust_score, 100)
    
    excitement_score = 0
    excitement_details = []
    images = soup.find_all('img')
    excitement_score += min(len(images) * 2, 30)
    excitement_details.append(f"{len(images)} images on page")
    
    videos = soup.find_all('video') + soup.find_all('iframe', src=re.compile(r'youtube|vimeo', re.I))
    if videos:
        excitement_score += 20
        excitement_details.append(f"{len(videos)} videos present")
    
    hero = soup.find(attrs={'class': re.compile(r'hero|banner', re.I)}) or soup.find('section', class_=re.compile(r'hero', re.I))
    if hero:
        excitement_score += 15
        excitement_details.append("Hero banner present")
    
    excitement_score = min(excitement_score, 100)
    
    pro_score = 0
    professional_indicators = []
    meta_desc = soup.find('meta', attrs={'name': 'description'})
    if meta_desc and len(meta_desc.get('content', '')) > 50:
        pro_score += 15
        professional_indicators.append("Good meta description")
    
    title = soup.find('title')
    if title and len(title.text) > 10:
        pro_score += 10
        professional_indicators.append("Proper page title")
    
    if response_time < 2:
        pro_score += 15
        professional_indicators.append(f"Fast loading ({response_time:.1f}s)")
    
    pro_score = min(pro_score, 100)
    
    return {
        'trust_score': trust_score,
        'trust_details': trust_details,
        'excitement_score': excitement_score,
        'excitement_details': excitement_details,
        'professionalism_score': pro_score,
        'professional_indicators': professional_indicators,
        'response_time': round(response_time, 2)
    }

# Competitor Scorecard
def get_demo_competitors(user_url):
    return [
        {'name': 'Amazon', 'url': 'https://amazon.com', 'load_time': 1.2, 'broken_links': 0, 'score': 95},
        {'name': 'eBay', 'url': 'https://ebay.com', 'load_time': 1.8, 'broken_links': 1, 'score': 82},
        {'name': 'AliExpress', 'url': 'https://aliexpress.com', 'load_time': 3.1, 'broken_links': 8, 'score': 71}
    ]

# Website Testing
@app.route('/api/test/website', methods=['POST'])
def test_website():
    data = request.get_json()
    url = data.get('url', '').strip()
    
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url
    
    try:
        headers = {'User-Agent': 'Mozilla/5.0'}
        page_start = time.time()
        response = requests.get(url, headers=headers, timeout=10)
        load_time = round(time.time() - page_start, 2)
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # 🔥 LINK COLLECTION - SAHI VERSION
        all_urls = []
        
        for link in soup.find_all('a', href=True):
            href = link['href'].strip()
            if href and not href.startswith('#') and not href.startswith('mailto:') and not href.startswith('javascript:'):
                full_url = get_absolute_url(url, href)
                if full_url and is_valid_url(full_url):
                    all_urls.append(full_url)
        
        all_urls = list(set(all_urls))
        print(f"🔗 Found {len(all_urls)} unique links")  # Terminal mein dikhega
        
        # Check each link
        broken_links = []
        working_links = []
        
        for link_url in all_urls[:50]:  # Limit to 50 for speed
            try:
                r = requests.head(link_url, timeout=3, allow_redirects=True)
                if r.status_code >= 400:
                    broken_links.append(link_url)
                else:
                    working_links.append(link_url)
            except:
                broken_links.append(link_url)
        
        # Technology detection
        technologies = []
        html_lower = response.text.lower()
        tech_map = {
            'React': ['react', 'reactjs'], 'Vue.js': ['vue', 'vuejs'],
            'Angular': ['angular', 'ng-'], 'jQuery': ['jquery'],
            'Bootstrap': ['bootstrap'], 'WordPress': ['wordpress', 'wp-content'],
            'Laravel': ['laravel'], 'Django': ['django']
        }
        for tech, patterns in tech_map.items():
            if any(p in html_lower for p in patterns):
                technologies.append(tech)
        
        total = len(all_urls)
        working = len(working_links)
        broken = len(broken_links)
        score = int((working / total) * 100) if total > 0 else 70
        
        result = {
            'url': url,
            'timestamp': datetime.now().isoformat(),
            'score': min(score, 100),
            'load_time': load_time,
            'technologies': technologies or ['Unknown'],
            'links': {
                'total': total,
                'working': working,
                'broken': broken,
                'broken_list': broken_links[:10]
            },
            'recommendations': [
                f"Fix {broken} broken links" if broken else "All links are healthy",
                "Consider modern JS framework" if not technologies else "Good tech stack",
                "Add SSL certificate" if not url.startswith('https') else "SSL active"
            ],
            'emotions': analyze_emotional_response(url, soup, headers),
            'competitors': get_demo_competitors(url)
        }
        
        return jsonify(result), 200
    
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({
            'url': url,
            'timestamp': datetime.now().isoformat(),
            'score': 0,
            'technologies': ['Error'],
            'links': {'total': 0, 'working': 0, 'broken': 0, 'broken_list': []},
            'recommendations': [f'Error: {str(e)}']
        }), 200

# Github Analysis
@app.route('/api/test/github', methods=['POST'])
def test_github():
    data = request.get_json()
    repo_url = data.get('url', '').strip()
    match = re.search(r'github\.com/([^/]+)/([^/]+)', repo_url)
    if not match:
        return jsonify({'error': 'Invalid GitHub URL'}), 400
    
    owner, repo = match.groups()
    try:
        headers = {'Accept': 'application/vnd.github.v3+json'}
        response = requests.get(f'https://api.github.com/repos/{owner}/{repo}', headers=headers)
        if response.status_code != 200:
            return jsonify({'error': 'Repository not found'}), 404
        data = response.json()
        languages = requests.get(f'https://api.github.com/repos/{owner}/{repo}/languages', headers=headers).json()
        readme_present = requests.get(f'https://api.github.com/repos/{owner}/{repo}/readme', headers=headers).status_code == 200
        score = 50
        stars = data.get('stargazers_count', 0)
        forks = data.get('forks_count', 0)
        issues = data.get('open_issues_count', 0)
        if stars > 100: score += 15
        elif stars > 50: score += 10
        if forks > 50: score += 10
        if issues < 5: score += 10
        if data.get('description'): score += 5
        if data.get('license'): score += 5
        if readme_present: score += 5
        recommendations = []
        if not data.get('description'): recommendations.append("Add repository description")
        if not data.get('license'): recommendations.append("Add a license file")
        if not readme_present: recommendations.append("Add a README.md file")
        if issues > 20: recommendations.append(f"Address {issues} open issues")
        return jsonify({
            'url': repo_url,
            'name': data.get('name'),
            'owner': data.get('owner', {}).get('login'),
            'timestamp': datetime.now().isoformat(),
            'score': min(score, 100),
            'stars': stars,
            'forks': forks,
            'open_issues': issues,
            'has_readme': readme_present,
            'has_license': bool(data.get('license')),
            'language': data.get('language', 'Unknown'),
            'all_languages': languages,
            'recommendations': recommendations
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Health Check
@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'}), 200

@app.route('/api/ai-suggest', methods=['POST'])
def ai_suggest():
    data = request.get_json()
    url = data.get('url', '')
    score = data.get('score', 0)
    broken = data.get('broken', 0)
    
    # Create prompt
    prompt = f"Instruction: Suggest fixes for website test results\nInput: URL: {url}, Score: {score}, Broken: {broken}\nOutput:"
    
    # Generate suggestion
    inputs = llm_tokenizer(prompt, return_tensors="pt")
    outputs = llm_model.generate(**inputs, max_new_tokens=100)
    suggestion = llm_tokenizer.decode(outputs[0], skip_special_tokens=True)
    
    # Extract only the output part
    if "Output:" in suggestion:
        suggestion = suggestion.split("Output:")[-1].strip()
    
    return jsonify({"suggestion": suggestion})

if __name__ == '__main__':
    print("\n" + "="*50)
    print("🔥 SQA TESTING AGENT BACKEND 🔥")
    print("="*50)
    print("✅ Website testing (links + technologies) - ACTIVE")
    print("✅ Emotional response detection - ACTIVE")
    print("✅ Competitor scorecard - ACTIVE")
    print("="*50)
    print("🌐 Server: http://localhost:5000")
    print("="*50)
    app.run(host='0.0.0.0', port=5000, debug=True)