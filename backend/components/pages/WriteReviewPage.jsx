import React, { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import { useNavigate, useParams, useLocation } from "react-router-dom";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import vendorServicesApi from "../../services/api/vendorServicesApi";
import {
  Box,
  Button,
  Card,
  CardContent,
  Container,
  TextField,
  Typography,
  Rating,
  Grid,
  LinearProgress,
  Stepper,
  Step,
  StepLabel,
  IconButton,
  Chip,
  Paper,
  Fade,
  Grow,
  Stack,
  Avatar,
  Divider,
  Alert,
} from "@mui/material";
import {
  ThumbUp,
  ThumbDown,
  CloudUpload,
  Close,
  ArrowBack,
  ArrowForward,
  Send,
} from "@mui/icons-material";
import { styled, ThemeProvider, createTheme } from "@mui/material/styles";

const API_BASE_URL = "https://happywedz.com/api";

const customTheme = createTheme({
  typography: {
    fontFamily: 'var(--rubik-font)',
    allVariants: {
      fontFamily: 'var(--rubik-font)',
    },
  },
  components: {
    MuiTypography: {
      styleOverrides: {
        root: {
          fontFamily: 'var(--rubik-font)',
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          fontFamily: 'var(--rubik-font)',
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          fontFamily: 'var(--rubik-font)',
        },
      },
    },
  },
});

const StyledCard = styled(Card)(({ theme }) => ({
  borderRadius: 24,
  boxShadow: "0 8px 40px rgba(0,0,0,0.12)",
  overflow: "visible",
  fontFamily: 'var(--rubik-font)',
}));

const RecommendButton = styled(Button)(({ theme, selected, variant }) => ({
  borderRadius: 16,
  padding: "32px 24px",
  fontSize: "1.1rem",
  fontWeight: 600,
  textTransform: "none",
  transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
  border: selected
    ? `3px solid ${variant === "yes" ? theme.palette.success.main : theme.palette.error.main}`
    : "3px solid #e0e0e0",
  backgroundColor: selected
    ? variant === "yes"
      ? "rgba(46, 125, 50, 0.1)"
      : "rgba(211, 47, 47, 0.1)"
    : "white",
  color: selected
    ? variant === "yes"
      ? theme.palette.success.main
      : theme.palette.error.main
    : theme.palette.text.secondary,
  "&:hover": {
    transform: "translateY(-4px)",
    boxShadow: "0 12px 24px rgba(0,0,0,0.15)",
    backgroundColor: selected
      ? variant === "yes"
        ? "rgba(46, 125, 50, 0.15)"
        : "rgba(211, 47, 47, 0.15)"
      : "#f5f5f5",
  },
}));

const ImagePreview = styled(Box)({
  position: "relative",
  width: 120,
  height: 120,
  borderRadius: 12,
  overflow: "hidden",
  boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
  "& img": {
    width: "100%",
    height: "100%",
    objectFit: "cover",
  },
});

const StyledRating = styled(Rating)(({ theme }) => ({
  "& .MuiRating-iconFilled": {
    color: "#ffc107",
  },
  "& .MuiRating-iconHover": {
    color: "#ffc107",
  },
  "& .MuiRating-icon": {
    fontSize: "2.5rem",
  },
}));

const WriteReviewPage = () => {
  const { vendorId } = useParams();
  const { user, token } = useSelector((state) => state.auth);
  const navigate = useNavigate();
  const location = useLocation();

  const [vendor, setVendor] = useState(null);
  const [loadingVendor, setLoadingVendor] = useState(true);
  const [step, setStep] = useState(0);
  const [formData, setFormData] = useState({
    would_recommend: null,
    rating_quality: 0,
    rating_responsiveness: 0,
    rating_professionalism: 0,
    rating_value: 0,
    rating_flexibility: 0,
    title: "",
    comment: "",
    happywedz_helped: "yes",
    guest_count: "",
    spent: "",
  });
  const [images, setImages] = useState([]);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!user || !token) {
      navigate("/customer-login", { state: { from: location } });
    }
  }, [user, token, navigate, location]);

  useEffect(() => {
    const fetchVendorData = async () => {
      if (!vendorId) return;
      try {
        setLoadingVendor(true);
        const data = await vendorServicesApi.getVendorServiceById(vendorId);
        setVendor(data.vendor);
      } catch (err) {
        console.error("Failed to load vendor data:", err);
        setError("Could not load vendor details. Please try again later.");
      } finally {
        setLoadingVendor(false);
      }
    };
    fetchVendorData();
  }, [vendorId]);

  const handleRecommendation = (value) => {
    setFormData({ ...formData, would_recommend: value });
    setError("");
    setTimeout(() => setStep(1), 300);
  };

  const handleStarClick = (field, value) => {
    setFormData({ ...formData, [field]: value });
    setError("");
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
    if (name === "title" || name === "comment") {
      setError("");
    }
  };

  const handleImageUpload = (e) => {
    const files = Array.from(e.target.files);
    const newImgs = files.map((file) => ({
      file,
      preview: URL.createObjectURL(file),
    }));
    setImages((prev) => [...prev, ...newImgs]);
  };

  const removeImage = (idx) => {
    setImages((prev) => prev.filter((_, i) => i !== idx));
  };

  const requiredRatings = [
    "rating_quality",
    "rating_responsiveness",
    "rating_professionalism",
    "rating_value",
    "rating_flexibility",
  ];

  const ratingLabels = {
    rating_quality: "Quality",
    rating_responsiveness: "Responsiveness",
    rating_professionalism: "Professionalism",
    rating_value: "Value",
    rating_flexibility: "Flexibility",
  };

  const handleNextClick = () => {
    setError("");
    if (step === 1) {
      const missing = requiredRatings.filter(
        (field) => !formData[field] || formData[field] === 0
      );
      if (missing.length > 0) {
        const names = missing.map((f) => ratingLabels[f]).join(", ");
        setError(`Please select a star rating for: ${names}`);
        return;
      }
      setStep(step + 1);
    } else if (step === 2) {
      if (!formData.title.trim()) {
        setError("Please provide a title for your review.");
        return;
      }
      if (!formData.comment.trim()) {
        setError("Please write a comment about your experience.");
        return;
      }
      setStep(step + 1);
    }
  };

  const handleSubmit = async () => {
    const emptyRating = requiredRatings.some(
      (field) => !formData[field] || formData[field] === 0
    );
    if (!formData.title.trim() || !formData.comment.trim() || emptyRating) {
      toast.error(
        "Please complete all required fields and ratings before submitting."
      );
      return;
    }

    const data = new FormData();
    Object.entries(formData).forEach(([key, value]) => data.append(key, value));
    images.forEach((img) => data.append("media", img.file));

    try {
      setSubmitting(true);
      const response = await fetch(`${API_BASE_URL}/reviews/${vendorId}`, {
        method: "POST",
        headers: { Authorization: `Bearer ${token}` },
        body: data,
      });

      const result = await response.json();
      if (!response.ok) throw new Error(result.message || "Failed to submit.");

      toast.success("Review submitted successfully!");
      navigate(-1);
    } catch (err) {
      toast.error(err.message);
    } finally {
      setSubmitting(false);
    }
  };

  const RatingInput = ({ label, field }) => (
    <Grid item xs={12} sm={6}>
      <Paper
        elevation={0}
        sx={{
          p: 3,
          borderRadius: 3,
          border: "1px solid #e0e0e0",
          transition: "all 0.3s ease",
          "&:hover": {
            borderColor: "#FF2A00",
            boxShadow: "0 4px 12px rgba(255, 215, 0, 0.2)",
          },
        }}
      >
        <Typography
          variant="subtitle1"
          fontWeight={600}
          gutterBottom
          color="text.primary"
        >
          {label}
        </Typography>
        <StyledRating
          value={formData[field]}
          onChange={(event, newValue) => handleStarClick(field, newValue)}
          size="large"
        />
      </Paper>
    </Grid>
  );

  if (loadingVendor) {
    return (
      <ThemeProvider theme={customTheme}>
        <Container maxWidth="md" sx={{ mt: 8 }}>
          <Box textAlign="center">
            <LinearProgress sx={{ borderRadius: 2 }} />
            <Typography variant="h6" sx={{ mt: 2 }} color="text.secondary">
              Loading vendor details...
            </Typography>
          </Box>
        </Container>
      </ThemeProvider>
    );
  }

  const steps = ["Recommendation", "Rate Experience", "Write Review", "Additional Details"];

  return (
    <ThemeProvider theme={customTheme}>
      <Box sx={{ bgcolor: "#f8f9fa", minHeight: "100vh", py: 2 }}>
        <ToastContainer position="top-center" autoClose={3000} />
        <Container maxWidth="lg">
          <Fade in timeout={800}>
            <StyledCard>
              <CardContent sx={{ p: { xs: 3, md: 5 } }}>
                {step === 0 ? (
                  <Box textAlign="center">
                    <Grow in timeout={600}>
                      <Box>
                        {vendor?.businessLogo && (
                          <Avatar
                            src={vendor.businessLogo}
                            alt={vendor.businessName}
                            sx={{
                              width: 140,
                              height: 140,
                              mx: "auto",
                              mb: 3,
                              boxShadow: "0 8px 24px rgba(0,0,0,0.12)",
                            }}
                          />
                        )}
                        <Typography
                          variant="h3"
                          fontWeight={700}
                          gutterBottom
                          sx={{ color: "#1a1a1a" }}
                        >
                          {vendor?.businessName}
                        </Typography>
                        <Chip
                          label={vendor?.vendorType?.name}
                          sx={{
                            mb: 5,
                            px: 2,
                            py: 0.5,
                            fontSize: "1rem",
                            fontWeight: 600,
                          }}
                          color="primary"
                          variant="outlined"
                        />

                        <Typography
                          variant="h4"
                          fontWeight={600}
                          sx={{ mb: 5, color: "#333" }}
                        >
                          Would you recommend this vendor?
                        </Typography>

                        <Grid container spacing={3} justifyContent="center">
                          <Grid item xs={12} sm={5}>
                            <RecommendButton
                              fullWidth
                              selected={formData.would_recommend === "yes"}
                              variant="yes"
                              onClick={() => handleRecommendation("yes")}
                              startIcon={<ThumbUp sx={{ fontSize: 40 }} />}
                            >
                              <Stack alignItems="center" spacing={1}>
                                <Typography variant="h5" fontWeight={700}>
                                  Yes
                                </Typography>
                                <Typography variant="caption">
                                  I'd recommend them
                                </Typography>
                              </Stack>
                            </RecommendButton>
                          </Grid>

                          <Grid item xs={12} sm={5}>
                            <RecommendButton
                              fullWidth
                              selected={formData.would_recommend === "no"}
                              variant="no"
                              onClick={() => handleRecommendation("no")}
                              startIcon={<ThumbDown sx={{ fontSize: 40 }} />}
                            >
                              <Stack alignItems="center" spacing={1}>
                                <Typography variant="h5" fontWeight={700}>
                                  No
                                </Typography>
                                <Typography variant="caption">
                                  Not recommended
                                </Typography>
                              </Stack>
                            </RecommendButton>
                          </Grid>
                        </Grid>
                      </Box>
                    </Grow>
                  </Box>
                ) : (
                  <>
                    <Typography
                      variant="h4"
                      fontWeight={700}
                      textAlign="center"
                      gutterBottom
                      sx={{ color: "#1a1a1a" }}
                    >
                      Write a Review
                    </Typography>
                    <Typography
                      variant="h6"
                      textAlign="center"
                      color="text.secondary"
                      gutterBottom
                      sx={{ mb: 4 }}
                    >
                      {vendor?.businessName}
                    </Typography>

                    <Stepper activeStep={step - 1} sx={{ mb: 5 }}>
                      {steps.slice(1).map((label) => (
                        <Step key={label}>
                          <StepLabel>{label}</StepLabel>
                        </Step>
                      ))}
                    </Stepper>

                    {error && (
                      <Alert severity="error" sx={{ mb: 3, borderRadius: 2 }}>
                        {error}
                      </Alert>
                    )}

                    <Fade in key={step} timeout={500}>
                      <Box>
                        {step === 1 && (
                          <Box>
                            <Typography
                              variant="h5"
                              fontWeight={600}
                              gutterBottom
                              sx={{ mb: 4, color: "#333" }}
                            >
                              How was your experience?
                            </Typography>
                            <Grid container spacing={3}>
                              <RatingInput label="Quality" field="rating_quality" />
                              <RatingInput
                                label="Responsiveness"
                                field="rating_responsiveness"
                              />
                              <RatingInput
                                label="Professionalism"
                                field="rating_professionalism"
                              />
                              <RatingInput label="Value" field="rating_value" />
                              <RatingInput
                                label="Flexibility"
                                field="rating_flexibility"
                              />
                            </Grid>
                          </Box>
                        )}

                        {step === 2 && (
                          <Stack spacing={3}>
                            <Box>
                              <Typography
                                variant="subtitle1"
                                fontWeight={600}
                                gutterBottom
                              >
                                Give your review a title *
                              </Typography>
                              <TextField
                                fullWidth
                                name="title"
                                placeholder="Amazing Experience"
                                value={formData.title}
                                onChange={handleChange}
                                sx={{
                                  "& .MuiOutlinedInput-root": {
                                    borderRadius: 2,
                                  },
                                }}
                              />
                            </Box>

                            <Box>
                              <Typography
                                variant="subtitle1"
                                fontWeight={600}
                                gutterBottom
                              >
                                Tell us about your experience *
                              </Typography>
                              <TextField
                                fullWidth
                                multiline
                                rows={6}
                                name="comment"
                                placeholder="Share the details of your experience with this vendor..."
                                value={formData.comment}
                                onChange={handleChange}
                                sx={{
                                  "& .MuiOutlinedInput-root": {
                                    borderRadius: 2,
                                  },
                                }}
                              />
                            </Box>

                            <Box>
                              <Typography
                                variant="subtitle1"
                                fontWeight={600}
                                gutterBottom
                              >
                                Add Photos (Optional)
                              </Typography>
                              <Button
                                variant="outlined"
                                component="label"
                                startIcon={<CloudUpload />}
                                sx={{
                                  borderRadius: 2,
                                  textTransform: "none",
                                  py: 1.5,
                                  borderStyle: "dashed",
                                  borderWidth: 2,
                                }}
                              >
                                Upload Images
                                <input
                                  type="file"
                                  multiple
                                  accept="image/*"
                                  hidden
                                  onChange={handleImageUpload}
                                />
                              </Button>

                              {images.length > 0 && (
                                <Box sx={{ display: "flex", flexWrap: "wrap", gap: 2, mt: 2 }}>
                                  {images.map((img, idx) => (
                                    <ImagePreview key={idx}>
                                      <img src={img.preview} alt="preview" />
                                      <IconButton
                                        size="small"
                                        onClick={() => removeImage(idx)}
                                        sx={{
                                          position: "absolute",
                                          top: 4,
                                          right: 4,
                                          bgcolor: "rgba(0,0,0,0.6)",
                                          color: "white",
                                          "&:hover": { bgcolor: "rgba(0,0,0,0.8)" },
                                        }}
                                      >
                                        <Close fontSize="small" />
                                      </IconButton>
                                    </ImagePreview>
                                  ))}
                                </Box>
                              )}
                            </Box>
                          </Stack>
                        )}

                        {step === 3 && (
                          <Grid container spacing={3}>
                            <Grid item xs={12} md={6}>
                              <Typography
                                variant="subtitle1"
                                fontWeight={600}
                                gutterBottom
                              >
                                Guest Count (Optional)
                              </Typography>
                              <TextField
                                fullWidth
                                type="number"
                                name="guest_count"
                                placeholder="Number of guests"
                                value={formData.guest_count}
                                onChange={handleChange}
                                sx={{
                                  "& .MuiOutlinedInput-root": {
                                    borderRadius: 2,
                                  },
                                }}
                              />
                            </Grid>

                            <Grid item xs={12} md={6}>
                              <Typography
                                variant="subtitle1"
                                fontWeight={600}
                                gutterBottom
                              >
                                Amount Spent (Optional)
                              </Typography>
                              <TextField
                                fullWidth
                                type="number"
                                name="spent"
                                placeholder="Amount in ₹"
                                value={formData.spent}
                                onChange={handleChange}
                                sx={{
                                  "& .MuiOutlinedInput-root": {
                                    borderRadius: 2,
                                  },
                                }}
                              />
                            </Grid>
                          </Grid>
                        )}
                      </Box>
                    </Fade>

                    <Divider sx={{ my: 4 }} />

                    <Stack direction="row" spacing={2} justifyContent="space-between">
                      <Button
                        className="btn-outline-primary"
                        size="large"
                        startIcon={<ArrowBack />}
                        onClick={() => {
                          setError("");
                          step === 1 ? setStep(0) : setStep(step - 1);
                        }}
                        sx={{
                          borderRadius: 2,
                          px: 4,
                          textTransform: "none",
                          fontWeight: 600,
                        }}
                      >
                        Back
                      </Button>

                      {step === 3 ? (
                        <Button
                          variant="contained"
                          size="large"
                          endIcon={submitting ? null : <Send />}
                          onClick={handleSubmit}
                          disabled={submitting}
                          sx={{
                            borderRadius: 2,
                            px: 4,
                            textTransform: "none",
                            fontWeight: 600,
                            boxShadow: "0 4px 12px rgba(25, 118, 210, 0.3)",
                          }}
                        >
                          {submitting ? "Submitting..." : "Submit Review"}
                        </Button>
                      ) : (
                        <Button
                          className="btn-primary"
                          variant="contained"
                          size="large"
                          endIcon={<ArrowForward />}
                          onClick={handleNextClick}
                          sx={{
                            borderRadius: 2,
                            px: 4,
                            textTransform: "none",
                            fontWeight: 600,
                          }}
                        >
                          Next
                        </Button>
                      )}
                    </Stack>
                  </>
                )}
              </CardContent>
            </StyledCard>
          </Fade>
        </Container>
      </Box>
    </ThemeProvider>
  );
};

export default WriteReviewPage;