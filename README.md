# allianz-assessment
Allianz Assessment

# API Architecture Solutions & Implementation Guide

## Scenario #2: Improved API Architecture

### Current Architecture Analysis

**Identified Weaknesses:**
1. **Over-exposure**: All APIs are public by design, even internal-only APIs
2. **Inefficient routing**: Internal traffic unnecessarily goes through internet → CloudFront → API Gateway
3. **Single point of failure**: One CloudFront distribution for all APIs
4. **Security gaps**: Regional API Gateway endpoints can be accessed directly, bypassing WAF
5. **No network segmentation**: Lack of private connectivity for internal services
6. **Limited governance**: No distinction between internal and external API management

### Proposed New Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                EXTERNAL CLIENTS                                 │
└─────────────────────────┬───────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            AMAZON CLOUDFRONT                                    │
│                         api.allianz-trade.com                                  │
│                                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │
│  │   Origin 1      │  │   Origin 2      │  │   Origin N      │                │
│  │ /auth/* path    │  │ /payment/* path │  │ /other/* path   │                │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                │
└─────────────────────────┬───────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         AWS GLOBAL WAF + SHIELD                                │
│                                                                                 │
│  • Geographic restrictions          • Rate limiting                            │
│  • IP whitelisting/blacklisting     • SQL injection protection                │
│  • Custom rules for API protection  • XSS protection                          │
└─────────────────────────┬───────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      PUBLIC API GATEWAY                                        │
│                   (External + Hybrid APIs)                                     │
│                                                                                 │
│  • Custom authorizer (Lambda)       • Request/Response transformation          │
│  • Usage plans and API keys         • Caching                                  │
│  • Resource policies                • Request validation                       │
└─────────────────────────┬───────────────────────────────────────────────────────┘
                          │
                          ▼

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              VPC                                               │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                        INTERNAL NETWORK                                 │   │
│  │                                                                         │   │
│  │  ┌───────────────────────────────────────────────────────────────────┐  │   │
│  │  │                 PRIVATE API GATEWAY                               │  │   │
│  │  │                  (Internal APIs Only)                            │  │   │
│  │  │                                                                   │  │   │
│  │  │  • VPC Endpoints                                                  │  │   │
│  │  │  • Private DNS resolution                                         │  │   │
│  │  │  • No internet access required                                    │  │   │
│  │  └───────────────────────────────────────────────────────────────────┘  │   │
│  │                                                                         │   │
│  │  ┌───────────────────────────────────────────────────────────────────┐  │   │
│  │  │                    INTERNAL ALB                                   │  │   │
│  │  │              (Load Balancer for ECS)                              │  │   │
│  │  │                                                                   │  │   │
│  │  │  • Internal routing                                               │  │   │
│  │  │  • Health checks                                                  │  │   │
│  │  │  • SSL termination                                                │  │   │
│  │  └───────────────────────────────────────────────────────────────────┘  │   │
│  │                                                                         │   │
│  │                            ▼                                           │   │
│  │                                                                         │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐        │   │
│  │  │   ECS FARGATE   │  │   ECS FARGATE   │  │     LAMBDA      │        │   │
│  │  │  Microservice 1 │  │  Microservice 2 │  │   Functions     │        │   │
│  │  │                 │  │                 │  │                 │        │   │
│  │  │  • Auth Service │  │ • Payment API   │  │ • Notifications │        │   │
│  │  │  • User Mgmt    │  │ • Transaction   │  │ • Data Process  │        │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘        │   │
│  └─────────────────────────────────────────────────────────────────────────┐   │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                           INTERNAL CLIENTS                                     │
│                                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │
│  │   Application   │  │   Application   │  │   Application   │                │
│  │    Server 1     │  │    Server 2     │  │    Server N     │                │
│  │                 │  │                 │  │                 │                │
│  │  Direct VPC     │  │  Direct VPC     │  │  Direct VPC     │                │
│  │  Connection     │  │  Connection     │  │  Connection     │                │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Implementation Strategy

#### Phase 1: Infrastructure Setup

**1. VPC Endpoint Configuration**
```hcl
# VPC Endpoint for API Gateway
resource "aws_vpc_endpoint" "api_gateway" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.execute-api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.api_gateway_endpoint.id]
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = [
          "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:*/*/internal/*"
        ]
      }
    ]
  })
  
  tags = {
    Name = "api-gateway-private-endpoint"
  }
}
```

**2. Private API Gateway Setup**
```hcl
resource "aws_api_gateway_rest_api" "private_api" {
  name = "allianz-trade-private-api"
  
  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.api_gateway.id]
  }
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "execute-api:Invoke"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:sourceVpce" = aws_vpc_endpoint.api_gateway.id
          }
        }
      }
    ]
  })
}
```

#### Phase 2: CloudFront Path-Based Routing

**CloudFront Distribution Configuration:**
```yaml
# CloudFront with multiple origins for path-based routing
Resources:
  CloudFrontDistribution:
    Type: AWS::CloudFront::Distribution
    Properties:
      DistributionConfig:
        Aliases:
          - api.allianz-trade.com
        
        Origins:
          - Id: auth-api-origin
            DomainName: !Sub "${AuthApiGateway}.execute-api.${AWS::Region}.amazonaws.com"
            OriginPath: /prod
            CustomOriginConfig:
              HTTPPort: 443
              OriginProtocolPolicy: https-only
              OriginSSLProtocols:
                - TLSv1.2
            OriginCustomHeaders:
              - HeaderName: X-Origin-Verify
                HeaderValue: !Ref OriginVerifySecret
                
          - Id: payment-api-origin
            DomainName: !Sub "${PaymentApiGateway}.execute-api.${AWS::Region}.amazonaws.com"
            OriginPath: /prod
            CustomOriginConfig:
              HTTPPort: 443
              OriginProtocolPolicy: https-only
              OriginSSLProtocols:
                - TLSv1.2
            OriginCustomHeaders:
              - HeaderName: X-Origin-Verify
                HeaderValue: !Ref OriginVerifySecret
        
        DefaultCacheBehavior:
          TargetOriginId: auth-api-origin
          ViewerProtocolPolicy: redirect-to-https
          AllowedMethods:
            - GET
            - HEAD
            - OPTIONS
            - PUT
            - POST
            - PATCH
            - DELETE
          CachedMethods:
            - GET
            - HEAD
            - OPTIONS
          Compress: true
          ForwardedValues:
            QueryString: true
            Headers:
              - Authorization
              - Content-Type
              - X-API-Key
        
        CacheBehaviors:
          - PathPattern: "/auth/*"
            TargetOriginId: auth-api-origin
            ViewerProtocolPolicy: redirect-to-https
            AllowedMethods:
              - GET
              - HEAD
              - OPTIONS
              - PUT
              - POST
              - PATCH
              - DELETE
            CachedMethods:
              - GET
              - HEAD
              - OPTIONS
            Compress: true
            TTL:
              DefaultTTL: 0
              MaxTTL: 0
              MinTTL: 0
            ForwardedValues:
              QueryString: true
              Headers:
                - "*"
                
          - PathPattern: "/payment/*"
            TargetOriginId: payment-api-origin
            ViewerProtocolPolicy: redirect-to-https
            AllowedMethods:
              - GET
              - HEAD
              - OPTIONS
              - PUT
              - POST
              - PATCH
              - DELETE
            CachedMethods:
              - GET
              - HEAD
              - OPTIONS
            Compress: true
            TTL:
              DefaultTTL: 0
              MaxTTL: 0
              MinTTL: 0
            ForwardedValues:
              QueryString: true
              Headers:
                - "*"
        
        WebACLId: !Ref GlobalWAF
        PriceClass: PriceClass_100
        Enabled: true
```

#### Phase 3: API Gateway Protection

**Resource Policy to Prevent Bypass:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:*:*:*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "eu-west-1"
        },
        "IpAddress": {
          "aws:SourceIp": [
            "CloudFront-Global-IP-List"
          ]
        },
        "StringLike": {
          "x-origin-verify": "your-secret-header-value"
        }
      }
    },
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:*:*:*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

### Migration Strategy

#### Step 1: Parallel Deployment (Week 1-2)
- Deploy private API Gateway alongside existing public APIs
- Set up VPC endpoints and internal routing
- Configure internal applications to use private endpoints
- Test internal connectivity without affecting external traffic

#### Step 2: CloudFront Enhancement (Week 3-4)
- Configure multiple origins in CloudFront
- Implement path-based routing
- Add custom headers for origin verification
- Test external API access through new routing

#### Step 3: Security Hardening (Week 5-6)
- Apply resource policies to prevent bypass
- Implement WAF rules on regional API Gateways
- Configure monitoring and alerting
- Conduct security testing

#### Step 4: Traffic Migration (Week 7-8)
- Gradually migrate internal traffic to private endpoints
- Update DNS records and service discovery
- Monitor performance and error rates
- Rollback capability maintained

#### Step 5: Cleanup (Week 9-10)
- Remove old public endpoints for internal APIs
- Clean up unused resources
- Update documentation and runbooks
- Final security review

### Benefits of New Architecture

1. **Enhanced Security**
   - Internal APIs not exposed to internet
   - Multiple layers of protection
   - Reduced attack surface

2. **Improved Performance**
   - Direct VPC routing for internal traffic
   - Reduced latency for internal calls
   - Better bandwidth utilization

3. **Cost Optimization**
   - Reduced CloudFront usage for internal traffic
   - Lower data transfer costs
   - Optimized API Gateway usage

4. **Better Governance**
   - Clear separation of internal vs external APIs
   - Centralized monitoring and logging
   - Consistent security policies

5. **Scalability**
   - Independent scaling of internal and external APIs
   - Better resource utilization
   - Flexible deployment options

### Monitoring and Observability

**Key Metrics to Track:**
- API Gateway request count and latency
- CloudFront cache hit ratio
- WAF blocked requests
- VPC endpoint utilization
- Internal vs external traffic patterns

**Alerting Strategy:**
- High error rates on API endpoints
- Unusual traffic patterns
- WAF rule violations
- VPC endpoint connectivity issues
- Performance degradation alerts